//
//  Helper+String.swift
//  FreeOfo
//
//  Created by yunba on 2017/11/14.
//  Copyright © 2017年 yunba. All rights reserved.
//

import Foundation

extension String {
    var upsideDownMac:String? {
        guard self.count == 12 else {return nil}
        var subArray = [String]()
        while subArray.count < 6 {
            let startIndex = self.index(self.startIndex, offsetBy: subArray.count * 2)
            let endIndex = self.index(startIndex, offsetBy: 2)
            subArray.append(self[startIndex..<endIndex])
        }
        var lastString = String()
        for i in stride(from: (subArray.count - 1), through: 0, by: -1) {
            lastString += subArray[i]
        }
        return lastString
    }
}
