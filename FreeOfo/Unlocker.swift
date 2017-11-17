//
//  Unlocker.swift
//  FreeOfo
//
//  Created by yunba on 2017/11/10.
//  Copyright © 2017年 yunba. All rights reserved.
//

import Foundation

class Unlocker {
    let macAddr:String
    let device_token:String
    let unlockOperation:UnlockOperation?
    
    init(mac: String, device_token: String, operation:UnlockOperation?) {
        macAddr = mac
        self.device_token = "#" + device_token
        unlockOperation = operation
    }
}

enum UnlockOperation:String {
    case unlock = "+J"
    case queryPassword = "?K"
    case setPassword = "+K\"1234\""
}
