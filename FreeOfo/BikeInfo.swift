//
//  BikeInfo.swift
//  FreeOfo
//
//  Created by yunba on 2017/11/21.
//  Copyright © 2017年 yunba. All rights reserved.
//

import Foundation

class bikeInfo {
    let bikeId:Int
    let macAddr:String
    let token:String
    let rawData:String
    
    init(bikeId: Int, macAddr:String, token:String, rawData:String) {
        self.bikeId = bikeId
        self.macAddr = macAddr
        self.token = token
        self.rawData = rawData
    }
}
