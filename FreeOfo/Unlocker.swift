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
    
    init(mac: String, device_token: String) {
        macAddr = mac
        self.device_token = "#" + device_token
    }
}
