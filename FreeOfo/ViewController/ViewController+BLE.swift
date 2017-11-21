//
//  ViewController+BLE.swift
//  FreeOfo
//
//  Created by yunba on 2017/11/17.
//  Copyright © 2017年 yunba. All rights reserved.
//

import Foundation
import CoreBluetooth
import RxBluetoothKit
import RxSwift


extension ViewController {
    func startScanning() {
        isScanInProgress = true
        unlockBtn.isEnabled = false
        logger(log: "scaning for peripheral", level: .good)
        print("scaning")
        scanningDisposable = manager.rx_state
            .filter { $0 == .poweredOn }
//            .timeout(4.0, scheduler: scheduler)
            .take(1)
            .flatMap { _ in self.manager.scanForPeripherals(withServices: [self.RX_SERVICE_UUID], options: nil).timeout(4.0, scheduler: MainScheduler.instance) }
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: {
                self.addNewScannedPeripheral($0)
            }, onError: { error in
                print("error accur - scaning: \(error.localizedDescription)")
                self.logger(log: "can't find peripheral! Stopped scaning", level: .error)
                self.stopScaning()
            })
    }

    private func addNewScannedPeripheral(_ peripheral: ScannedPeripheral) {
        if let data = peripheral.advertisementData.manufacturerData {
            let dataString = data.hexadecimalString
            let index = dataString.index(dataString.startIndex, offsetBy: 4)
            let scanedMacAddr = dataString[index...]
            
            print("scaned : \(scanedMacAddr)")
            if let macAddr = unlocker?.macAddr.upsideDownMac {
//                logger(log: "got macAddr in ofo \(macAddr)", level: .good)
                if macAddr.lowercased() == scanedMacAddr {
                    logger(log: "scaned peripheral: \(scanedMacAddr)", level: .good)
                    connectForUnlocking(peripheral: peripheral)
                    scanningDisposable?.dispose()
                }
            }
        }
    }
    
    func connectForUnlocking(peripheral: ScannedPeripheral) {
        manager.connect(peripheral.peripheral)
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else { return }
                self.logger(log: "connected", level:.info)
                self.connectedPeripheral = $0
                self.monitorDisconnection(for: $0)
                self.downloadServices(for: $0)
                }, onError: { (error) in
                    print("connection error, \(error.localizedDescription)")
            }).disposed(by: BLEdisposeBag)
    }
    
    private func monitorDisconnection(for peripheral: Peripheral) {
        manager.monitorDisconnection(for: peripheral)
            .subscribe(onNext: { [weak self] (peripheral) in
//                let alert = UIAlertController(title: "Disconnected!", message: "Peripheral Disconnected", preferredStyle: .alert)
//                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//                self?.present(alert, animated: true, completion: nil)
                self?.logger(log: "Peripheral Disconnected", level: .error)
            }).disposed(by: BLEdisposeBag)
    }
    
    private func downloadServices(for peripheral: Peripheral) {
        peripheral.discoverServices([RX_SERVICE_UUID])
            .flatMap { Observable.from($0) }
            .flatMap { $0.discoverCharacteristics([self.RX_CHAR_UUID])}
            .flatMap { Observable.from($0) }
            .flatMap { $0.readValue() }
            .subscribe(onNext: {
                let data = $0.value
                self.logger(log: "didDiscover Service, \(data?.hexadecimalString ?? "")", level: .info)
                if $0.uuid == self.RX_CHAR_UUID {
                    self.monitorCharacteristic(characteristic: $0)
                    self.writeToken(peripheral: peripheral)
                }
            }).disposed(by: BLEdisposeBag)
    }
    
    private func writeToken(peripheral: Peripheral) {
        peripheral.discoverServices([RX_SERVICE_UUID])
            .flatMap { Observable.from($0) }
            .flatMap { $0.discoverCharacteristics([self.TX_CHAR_UUID])}
            .flatMap { Observable.from($0) }
            .subscribe(onNext: { chart in
                self.writeCharateristic = chart
                self.logger(log: "wirting token to peripheral", level: .good)
                self.write2Characteristic(characteristic: chart, data: self.unlocker!.device_token.data(using: .utf8)!)
            }).disposed(by: BLEdisposeBag)
    }
    
    private func monitorCharacteristic(characteristic:Characteristic) {
        characteristic.setNotificationAndMonitorUpdates()
            .subscribe(onNext: {
                let newValue = $0.value
                if let lockStatus = String(data: newValue!, encoding:.utf8) {
                    if lockStatus == "ok" {
                        self.logger(log: "[write token] got peripheral response ok", level: .good)
                        var command = String()
                        if let cmd = self.unlocker!.unlockOperation {
                            command = cmd.rawValue
                        } else {
                            command = self.customCommand.text ?? ""
                        }
                        self.writeCommand(characteristic: self.writeCharateristic!, command: command)
                    } else {
                        self.logger(log: lockStatus, level: .good)
                    }
                }
            }).disposed(by: BLEdisposeBag)
    }
    
    private func write2Characteristic(characteristic: Characteristic, data:Data) {
        characteristic.writeValue(data, type: .withResponse)
            .subscribe { event in
                //respond to errors / successful write
                switch event {
                case .completed:
                    self.logger(log: "write token completed!", level: .good)
                case .error(_):
                    return
                case .next(let chart):
                    print("ongoing")
                    print(chart.value?.hexadecimalString as Any)
                }
            }.disposed(by: BLEdisposeBag)
    }
    
    private func writeCommand(characteristic: Characteristic, command: String) {
        let data = command.data(using: .utf8)!
        characteristic.writeValue(data, type: .withResponse)
            .subscribe{ event in
                switch event {
                case .completed:
                    print("write unlock command to peripheral completed!")
                    self.connectedPeripheral!.cancelConnection().subscribe{ event in
                        print("disconnected! ")
                        self.cancleConnect()
                        }.disposed(by: self.BLEdisposeBag)
                case .error(let error):
                    print(error.localizedDescription)
                case .next(_):
                    print("ongoing")
                }
            }.disposed(by: BLEdisposeBag)
    }
    
    private func stopScaning() {
        scanningDisposable?.dispose()
        isScanInProgress = false
        unlockBtn.isEnabled = true
    }
    
    private func cancleConnect() {
        scanningDisposable?.dispose()
        self.BLEdisposeBag = DisposeBag()
        isScanInProgress = false
        unlockBtn.isEnabled = true
    }
    
    func alertUser(alert:String) {
        let alert = UIAlertController(title: "Error!", message: alert, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
