//
//  SqlDSL.swift
//  FreeOfo
//
//  Created by yunba on 2017/11/21.
//  Copyright © 2017年 yunba. All rights reserved.
//

import Foundation

struct SqlDSL {
    static let field_bike_id      = "bike_id"
    static let field_mac_addr     = "mac_addr"
    static let field_token        = "token"
    static let field_bike_rawData = "raw_data"
    
    static let createTable = "create table bikeinfo (\(field_bike_id) integer primary key not null, \(field_mac_addr) text not null, \(field_token) text not null, \(field_bike_rawData) blob not null)"
    
    static func insertBikeInfo(bikeId: Int, macAddr:String, token:String) -> String {
        let insertDSL = "insert into bikeinfo (\(field_bike_id), \(field_mac_addr), \(field_token), \(field_bike_rawData)) values (\(bikeId), \(macAddr), \(token), ?)"
        return insertDSL
    }
    
    static var queryBikeInfo: String {
        get {
            let queryDSL = "select * from bikeinfo where \(field_bike_id) = ?"
            return queryDSL
        }
    }
}
