//
//  UnlockerViewController.swift
//  FreeOfo
//
//  Created by yunba on 2017/11/10.
//  Copyright © 2017年 yunba. All rights reserved.
//

import UIKit
import RxBluetoothKit
import RxSwift
import CoreBluetooth

class UnlockerViewController: UIViewController {
    private let RX_SERVICE_UUID = CBUUID(string: "89560001-b5a3-f393-e0a9-e50e24dcca9e")
    private let RX_CHAR_UUID    = CBUUID(string: "89560003-b5a3-f393-e0a9-e50e24dcca9e")
    private let TX_CHAR_UUID    = CBUUID(string: "89560002-b5a3-f393-e0a9-e50e24dcca9e")
    
    private let UNLOCK_COMMAND       = "+J"
    private let GET_PASSWORD_COMMAND = "?K"
    
    @IBOutlet weak var logLabel: UILabel!

    private var scanningDisposable: Disposable?
    private var scheduler: ConcurrentDispatchQueueScheduler!
    
    fileprivate var peripheralsArray: [ScannedPeripheral] = []
    fileprivate var servicesList: [Service] = []

    private var isScanInProgress = false
    private var connectedPeripheral: Peripheral?
    private var disposeBag = DisposeBag()
    
    var manager = BluetoothManager(queue: .main)
    var scannedPeripheral: ScannedPeripheral!
    private var writeCharateristic:Characteristic?
    
    var unlocker:Unlocker?

    override func viewDidLoad() {
        super.viewDidLoad()
        let timerQueue = DispatchQueue(label: "io.yunba.timer")
        scheduler = ConcurrentDispatchQueueScheduler(queue: timerQueue)
        // Do any additional setup after loading the view.
        logLabel.lineBreakMode = .byWordWrapping
        logLabel.numberOfLines = 0;
        logLabel.adjustsFontSizeToFitWidth = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startScanning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func stopScanning() {
        scanningDisposable?.dispose()
        self.disposeBag = DisposeBag()
        isScanInProgress = false
    }
    
    private func startScanning() {
        isScanInProgress = true
        log2Label(log: "scaning")
        scanningDisposable = manager.rx_state
            .take(1)
            .timeout(4.0, scheduler: scheduler)
            .flatMap { _ in self.manager.scanForPeripherals(withServices: [self.RX_SERVICE_UUID], options: nil) }
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: {
                self.addNewScannedPeripheral($0)
            }, onError: { error in
                print("error accur - scaning: \(error.localizedDescription)")
            })
    }

    @IBAction func goBack(_ sender: Any) {
        scanningDisposable?.dispose()
        self.disposeBag = DisposeBag()
        isScanInProgress = false
        self.performSegue(withIdentifier: "unwind2Main", sender: nil)
    }
    
    private func addNewScannedPeripheral(_ peripheral: ScannedPeripheral) {
        if let data = peripheral.advertisementData.manufacturerData {
            let dataString = data.hexadecimalString
            let index = dataString.index(dataString.startIndex, offsetBy: 4)
            let scanedMacAddr = dataString[index...]
            
            log2Label(log: "scaned : \(scanedMacAddr)")
            if let macAddr = unlocker?.macAddr.upsideDownMac {
                log2Label(log: "got macAddr in ofo \(macAddr)")
                if macAddr.lowercased() == scanedMacAddr {
                    connectForUnlocking(peripheral: peripheral)
                }
            }
        }
    }
    
    func connectForUnlocking(peripheral: ScannedPeripheral) {
        manager.connect(peripheral.peripheral)
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else { return }
//                self.title = "Connected"
                self.log2Label(log: "connected")
                self.connectedPeripheral = $0
                self.monitorDisconnection(for: $0)
                self.downloadServices(for: $0)
                }, onError: { _ in
            }).disposed(by: disposeBag)
    }
    
    private func monitorDisconnection(for peripheral: Peripheral) {
        manager.monitorDisconnection(for: peripheral)
            .subscribe(onNext: { [weak self] (peripheral) in
                let alert = UIAlertController(title: "Disconnected!", message: "Peripheral Disconnected", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }).disposed(by: disposeBag)
    }

    private func downloadServices(for peripheral: Peripheral) {
        peripheral.discoverServices([RX_SERVICE_UUID])
            .flatMap { Observable.from($0) }
            .flatMap { $0.discoverCharacteristics([self.RX_CHAR_UUID])}
            .flatMap { Observable.from($0) }
            .flatMap { $0.readValue() }
            .subscribe(onNext: {
                let data = $0.value
                self.log2Label(log: "didDiscover Service, \(data?.hexadecimalString ?? "")")
                if $0.uuid == self.RX_CHAR_UUID {
                    self.monitorCharacteristic(characteristic: $0)
                    self.writeToken(peripheral: peripheral)
                }
            }).disposed(by: disposeBag)
    }
    
    private func writeToken(peripheral: Peripheral) {
        peripheral.discoverServices([RX_SERVICE_UUID])
            .flatMap { Observable.from($0) }
            .flatMap { $0.discoverCharacteristics([self.TX_CHAR_UUID])}
            .flatMap { Observable.from($0) }
            .subscribe(onNext: { chart in
                self.writeCharateristic = chart
                self.write2Characteristic(characteristic: chart, data: self.unlocker!.device_token.data(using: .utf8)!)
            }).disposed(by: disposeBag)
    }
    
    private func monitorCharacteristic(characteristic:Characteristic) {
        characteristic.setNotificationAndMonitorUpdates()
            .subscribe(onNext: {
                let newValue = $0.value
                if let lockStatus = String(data: newValue!, encoding:.utf8) {
                    if lockStatus == "ok" {
                        self.log2Label(log: "got ok")
                        self.writeCommand(characteristic: self.writeCharateristic!, command: self.UNLOCK_COMMAND)
                    }
                }
            }).disposed(by: disposeBag)
    }
    
    private func write2Characteristic(characteristic: Characteristic, data:Data) {
        characteristic.writeValue(data, type: .withResponse)
            .subscribe { event in
                //respond to errors / successful write
                switch event {
                case .completed:
                    self.log2Label(log: "completed !")
                case .error(_):
                    return
                case .next(let chart):
                    print("ongoing")
                    print(chart.value?.hexadecimalString as Any)
                }
        }.disposed(by: disposeBag)
    }
    
    private func writeCommand(characteristic: Characteristic, command: String) {
        let data = command.data(using: .utf8)!
        characteristic.writeValue(data, type: .withResponse)
            .subscribe{ event in
                switch event {
                case .completed:
                    print("completed! ")
                case .error(let error):
                    print(error.localizedDescription)
                case .next(_):
                    print("ongoing")
                }
        }.disposed(by: disposeBag)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
extension UnlockerViewController {
    func log2Label(log: String) {
        self.logLabel.text = self.logLabel.text! + log + "\n"
    }
}
