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

class ViewController: UIViewController {
    
    let scanBtn = UIButton.init(type: .custom)
    let inputField = UITextField()
    let unlockBtn = UIButton.init(type: .custom)
    
    let provider = MoyaProvider<OfoReq>()
    
    let evenBus = PublishSubject<Bool>()
    
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        initChildView()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        inputField.rx.text
            .map{if $0 != nil {return Int($0!) != nil} else {return false}}
            .bind(to:unlockBtn.rx.isEnabled)
            .disposed(by: disposeBag)
        
        unlockBtn.rx.tap.subscribe(onNext:{ [unowned self] in
            self.provider.request(.get_with_url_lock(token: Helper.getToken(carno: self.inputField.text!), carno:self.inputField.text!)){ result in
                                                        switch result {
                                                        case let .success(resp):
                                                            let jsonResp = JSON(resp.data)
                                                            if jsonResp["data"].exists() {
                                                                self.queryLockInfo(lockSn: jsonResp["data"][0]["sn"].stringValue)
                                                            }
                                                        case let .failure(error):
                                                            print(error)
                                                        }
            }
        }).disposed(by: disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //FIXME: set corner radius in the function is not working
        super.viewDidAppear(animated)
        scanBtn.layer.cornerRadius = scanBtn.bounds.size.width * 0.5
        print(scanBtn.bounds.size.width)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initChildView() {
        //scan button style
        scanBtn.addWithStyle(isCircle:true, title: "扫描解锁", backgroundColor: .gray) {
            self.view.addSubview($0)
            $0.snp.makeConstraints({(make) -> Void in
                make.centerX.equalTo(self.view.snp.centerX)
                make.top.equalTo(self.view.snp.top).offset(60)
                make.height.equalTo(self.view.snp.height).multipliedBy(0.2)
                make.width.equalTo(scanBtn.snp.height)
            })
        }
        
        //input field style
        view.addSubview(inputField)
        inputField.keyboardType = .numberPad
        inputField.font = UIFont.systemFont(ofSize: 40.0)
        inputField.snp.makeConstraints({(make) -> Void in
            make.height.equalTo(view).multipliedBy(0.15)
            make.left.equalTo(view).offset(20)
            make.right.equalTo(view).offset(-20)
            make.top.equalTo(scanBtn.snp.bottom).offset(30)
        })
        inputField.setBottomBorder()
        
        //unlock button style
        unlockBtn.addWithStyle(isCircle: false, title: "点击解锁", backgroundColor: .white) {
            self.view.addSubview($0)
            $0.snp.makeConstraints({(make) -> Void in
                make.top.equalTo(inputField.snp.bottom).offset(20)
                make.left.equalTo(view).offset(40)
                make.right.equalTo(view).offset(-40)
                make.height.equalTo(40)
            })
            $0.layer.borderWidth = 2.0
            $0.layer.borderColor = UIColor.gray.cgColor
        }
        unlockBtn.setTitleColor(.gray, for: .normal)
        unlockBtn.setTitleColor(.blue, for: .disabled)
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
                    self.performSegue(withIdentifier: "ForUnlock", sender: Unlocker(mac: macAddr, device_token: deviceToken))
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

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {return}
        if identifier == "ForUnlock" {
            let unlockViewController = segue.destination as! UnlockerViewController
            if let unlocker = sender as? Unlocker {
                unlockViewController.unlocker = unlocker
            }
        }
    }
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
