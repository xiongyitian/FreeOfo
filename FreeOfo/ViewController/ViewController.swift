//
//  ViewController.swift
//  FreeOfo
//
//  Created by yunba on 2017/11/8.
//  Copyright © 2017年 yunba. All rights reserved.
//

import UIKit
import Moya
import SnapKit
import RxSwift
import RxCocoa
import SwiftyJSON
import CoreBluetooth
import RxBluetoothKit

class ViewController: UIViewController {
    
    let RX_SERVICE_UUID = CBUUID(string: "89560001-b5a3-f393-e0a9-e50e24dcca9e")
    let RX_CHAR_UUID    = CBUUID(string: "89560003-b5a3-f393-e0a9-e50e24dcca9e")
    let TX_CHAR_UUID    = CBUUID(string: "89560002-b5a3-f393-e0a9-e50e24dcca9e")

    
    let scanBtn = UIButton.init(type: .custom)
    let inputField = UITextField()
    let unlockBtn = UIButton.init(type: .custom)
    
    let provider = MoyaProvider<OfoReq>()
    
    let evenBus = PublishSubject<Bool>()
    
    @IBOutlet weak var outerScrollView: UIScrollView!
    @IBOutlet weak var tabBarItem1: UITabBarItem!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var customCommand: UITextField!
    @IBOutlet weak var operationType: UISegmentedControl!
    @IBOutlet weak var logScrollView: UIScrollView!
    let disposeBag = DisposeBag()
    var activeTextField: UITextField?

    
    var scanningDisposable: Disposable?
    var scheduler: ConcurrentDispatchQueueScheduler!
    
    fileprivate var peripheralsArray: [ScannedPeripheral] = []
    fileprivate var connectedPeripherals:[Peripheral] = []
    fileprivate var servicesList: [Service] = []
    
    var isScanInProgress = false
    var connectedPeripheral: Peripheral?
    var BLEdisposeBag = DisposeBag()
    
    var manager = BluetoothManager(queue: .main)
    var scannedPeripheral: ScannedPeripheral!
    var writeCharateristic:Characteristic?
    
    var unlocker:Unlocker?


    override func viewDidLoad() {
        super.viewDidLoad()
        initChildView()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        let timerQueue = DispatchQueue(label: "io.yunba.timer")
        scheduler = ConcurrentDispatchQueueScheduler(queue: timerQueue)
        let stateObservable = manager.rx_state
        stateObservable.subscribe(onNext: {
            switch $0{
            case .poweredOn:
                return
            case .poweredOff:
                self.alertUser(alert: "请打开蓝牙")
            case .unauthorized:
                self.alertUser(alert: "请允许使用蓝牙")
            case .unsupported:
                self.alertUser(alert: "不支持蓝牙的设备")
            case .unknown:
                self.alertUser(alert: "未知蓝牙状态")
            default:
                return
            }
        }).disposed(by: disposeBag)

        inputField.rx.text
            .map{if $0 != nil {return Int($0!) != nil} else {return false}}
            .bind(to:unlockBtn.rx.isEnabled)
            .disposed(by: disposeBag)
        
        unlockBtn.rx.tap.subscribe(onNext:{ [unowned self] in
            self.getWithUrl()
        }).disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addKeyboradShowOrHideObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboradShowOrHideObserver()
    }

    
    override func viewDidAppear(_ animated: Bool) {
        //FIXME: set corner radius in the function is not working
        super.viewDidAppear(animated)
//        scanBtn.layer.cornerRadius = scanBtn.bounds.size.width * 0.5
//        print(scanBtn.bounds.size.width)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initChildView() {
        //scan button style
//        scanBtn.addWithStyle(isCircle:true, title: "扫描解锁", backgroundColor: .gray) {
//            self.view.addSubview($0)
//            $0.snp.makeConstraints({(make) -> Void in
//                make.centerX.equalTo(self.view.snp.centerX)
//                make.top.equalTo(self.view.snp.top).offset(60)
//                make.height.equalTo(self.view.snp.height).multipliedBy(0.2)
//                make.width.equalTo(scanBtn.snp.height)
//            })
//        }
        
        //input field style
        contentView.addSubview(inputField)
        inputField.keyboardType = .numberPad
        inputField.font = UIFont.systemFont(ofSize: 40.0)
        inputField.placeholder = "单车编号"
        inputField.snp.makeConstraints({(make) -> Void in
            make.height.equalTo(view).multipliedBy(0.15)
            make.left.equalTo(view).offset(20)
            make.right.equalTo(view).offset(-20)
            make.top.equalTo(customCommand.snp.bottom).offset(10)
        })
        inputField.setBottomBorder()
        
        //unlock button style
        unlockBtn.addWithStyle(isCircle: false, title: "点击解锁", backgroundColor: .white) {
            self.contentView.addSubview($0)
            $0.snp.makeConstraints({(make) -> Void in
                make.top.greaterThanOrEqualTo(inputField.snp.bottom).offset(10)
                make.left.equalTo(self.contentView).offset(40)
                make.right.equalTo(self.contentView).offset(-40)
                make.height.equalTo(40)
                make.bottom.equalTo(self.view.snp.bottom).offset(-75)
            })
            $0.layer.cornerRadius = 5.0
        }
        unlockBtn.setTitleColor(.white, for: .normal)
//        unlockBtn.backgroundColor = UIColor.init(red: 26, green: 173, blue: 25, alpha: 1)
//        unlockBtn.setTitleColor(.blue, for: .disabled)
    }
    
    func getWithUrl(){
        let timestamp = Date().millisecondsString
        self.provider.request(.get_with_url_lock(token: Helper.getToken(carno: self.inputField.text!, timestamp: timestamp), carno:self.inputField.text!, timestamp: timestamp)){ result in
            print(Helper.getToken(carno: self.inputField.text!, timestamp: timestamp))
            switch result {
            case let .success(resp):
                let jsonResp = JSON(resp.data)
                print(jsonResp.rawString([.castNilToNSNull: true, .jsonSerialization: true])!)
                
                self.logger(log: "get data: \(jsonResp["data"][0]["sn"].stringValue)", level: .info)
                if jsonResp["data"].exists() {
                    self.queryLockInfo(lockSn: jsonResp["data"][0]["sn"].stringValue)
                }
            case let .failure(error):
                print(error)
            }
        }
    }
    
    func queryLockInfo(lockSn: String){
        provider.request(.query_info(lockSn: lockSn), completion: { result in
            switch result {
            case let .success(resp):
                let jsonResp = JSON(resp.data)
                if jsonResp["data"].exists() {
                    let macAddr = jsonResp["data"][0]["mac"].stringValue
                    let deviceToken = jsonResp["data"][0]["device_token"].stringValue
                    print("macAddr:\(macAddr); deviceToken:\(deviceToken)")
                    var op:UnlockOperation?
                    switch self.operationType.selectedSegmentIndex {
                        case 0:
                            op = .unlock
                        case 1:
                            op = .queryPassword
                        case 2:
                            op = .setPassword
                        default:
                            op = nil
                    }
                    self.unlocker = Unlocker(mac: macAddr, device_token: deviceToken, operation: op)
                    self.startScanning()
//                    self.performSegue(withIdentifier: "ForUnlock", sender: Unlocker(mac: macAddr, device_token: deviceToken, operation: nil))
                }
            case .failure(_):
                break
            }
        })
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func addKeyboradShowOrHideObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillBeHidden(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func removeKeyboradShowOrHideObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWasShown(notification: NSNotification)
    {
        //Need to calculate keyboard exact size due to Apple suggestions
        self.outerScrollView.isScrollEnabled = true
//        let info : NSDictionary = notification.userInfo! as NSDictionary
        let keyboardSize = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.size
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0)
        
        self.outerScrollView.contentInset = contentInsets
        self.outerScrollView.scrollIndicatorInsets = contentInsets
        
        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize.height
        if activeTextField != nil
        {
            if (!aRect.contains(activeTextField!.frame.origin))
            {
                self.outerScrollView.scrollRectToVisible(activeTextField!.frame, animated: true)
            }
        }
    }
    
    @objc func keyboardWillBeHidden(notification: NSNotification)
    {
        //Once keyboard disappears, restore original positions
//        let info : NSDictionary = notification.userInfo! as NSDictionary
//        let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let keyboardSize = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.size
        let contentInsets : UIEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, -keyboardSize.height, 0.0)
        self.outerScrollView.contentInset = contentInsets
        self.outerScrollView.scrollIndicatorInsets = contentInsets
        self.view.endEditing(true)
        self.outerScrollView.isScrollEnabled = true
//        self.outerScrollView.contentInset = UIEdgeInsets.zero
//        self.outerScrollView.scrollIndicatorInsets = UIEdgeInsets.zero
//        self.view.endEditing(true)
    }

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        guard let identifier = segue.identifier else {return}
//        if identifier == "ForUnlock" {
//            let unlockViewController = segue.destination as! UnlockerViewController
//            if let unlocker = sender as? Unlocker {
//                unlockViewController.unlocker = unlocker
//            }
//        }
//    }
}

//Date helper
extension Date {
    var millisecondsSince1970:Double {
        return (self.timeIntervalSince1970 * 1000.0).rounded()
    }
    var millisecondsString:String {
        return String(format: "%.0f", self.millisecondsSince1970)
    }
}
