//
//  SqliteManager.swift
//  FreeOfo
//
//  Created by yunba on 2017/11/21.
//  Copyright © 2017年 yunba. All rights reserved.
//

import Foundation

class SqlManager {
    static let shared: SqlManager = SqlManager()
    let databaseFileName = "database.sqlite"
    var pathToDatabase: String
    var database: FMDatabase?
    
    init() {
        let documentsDir = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString) as String
        pathToDatabase = documentsDir + "/" + databaseFileName
        print(pathToDatabase)
    }
    
    func createDatabase() -> Bool {
        var created = false
        
        if !FileManager.default.fileExists(atPath: pathToDatabase) {
            database = FMDatabase(path: pathToDatabase)
            if database != nil {
                if database!.open() {
                    do {
                        try database?.executeUpdate(SqlDSL.createTable, values: nil)
                        created = true
                    } catch {
                        print("could not create table: \(error.localizedDescription)")
                    }
                    database?.close()
                } else {
                    print("could not open database")
                }
            }
        }
        
        return created
    }
    
    func openDatabase() -> Bool {
        if database == nil {
            if FileManager.default.fileExists(atPath: pathToDatabase){
                database = FMDatabase(path: pathToDatabase)
            }
        }
        if database != nil {
            if database!.open() {
                return true
            }
        }
        return false
    }
    
    func insertBikeInfo(bikeId: Int, macAddr:String, token:String, rawData:Data) {
        if openDatabase() {
            let query = SqlDSL.insertBikeInfo(bikeId: bikeId, macAddr: macAddr, token: token)
            do {
                try database?.executeUpdate(query, values: [rawData])
            } catch {
                print("could not insert data, \(error.localizedDescription)")
            }
            database?.close()
        }
    }
    
    func queryInfo(bikeId:Int) -> [bikeInfo]? {
        var bikeInfos = [bikeInfo]()
        if openDatabase() {
            let query = SqlDSL.queryBikeInfo
            do {
                if let result = try database?.executeQuery(query, values: [bikeId]) {
                    while result.next() {
                        let bike:bikeInfo = bikeInfo(bikeId: Int(result.int(forColumn: SqlDSL.field_bike_id)),
                                                     macAddr: result.string(forColumn: SqlDSL.field_mac_addr)!,
                                                     token: result.string(forColumn: SqlDSL.field_token)!,
                                                     rawData: result.string(forColumn: SqlDSL.field_bike_rawData)!)
                        bikeInfos.append(bike)
                    }
                }
            } catch {
                print("cannot query in database: \(error.localizedDescription)")
            }
            database?.close()
        }
        if bikeInfos.count == 0 {
            return nil
        } else {return bikeInfos}
    }
}
