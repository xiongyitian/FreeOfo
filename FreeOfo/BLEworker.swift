//
//  BLEworker.swift
//  FreeOfo
//
//  Created by yunba on 2017/11/9.
//  Copyright © 2017年 yunba. All rights reserved.
//

import Foundation
import CoreBluetooth
import RxBluetoothKit
import RxSwift

class BleWorker {
    private let RX_SERVICE_UUID = CBUUID(string: "89560001-b5a3-f393-e0a9-e50e24dcca9e")
    
    private var scanningDisposable: Disposable?
    private var scheduler: ConcurrentDispatchQueueScheduler!
    fileprivate var peripheralsArray: [ScannedPeripheral] = []


    var manager = BluetoothManager(queue: .main)
    var scannedPeripheral: ScannedPeripheral!
    
    public func getManager() -> BluetoothManager{
        return self.manager
    }
    
    private func startScaning() {
        scanningDisposable = manager.rx_state
            .timeout(4.0, scheduler: scheduler)
            .take(1)
            .flatMap { _ in self.manager.scanForPeripherals(withServices: [self.RX_SERVICE_UUID], options: nil) }
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: {
                self.addNewScannedPeripheral($0)
            }, onError: { _ in
            })
    }
    
    private func addNewScannedPeripheral(_ peripheral: ScannedPeripheral) {
        let mapped = peripheralsArray.map { $0.peripheral }
        if let indx = mapped.index(of: peripheral.peripheral) {
            peripheralsArray[indx] = peripheral
        } else {
            peripheralsArray.append(peripheral)
        }
        print(peripheralsArray)
    }

}
