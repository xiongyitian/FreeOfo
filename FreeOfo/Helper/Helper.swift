//
//  Helper.swift
//  FreeOfo
//
//  Created by yunba on 2017/11/10.
//  Copyright © 2017年 yunba. All rights reserved.
//

import Foundation
import SwiftyJSON

struct Helper {
    static let auth_key   = "dwy6fiY2WYorbFoK"
    static let secret_key = "kCAevYplcaJiEQvYYJsDr6mkWm19kArv"
    static let basic_json_param = JSON(["auth_key": Helper.auth_key,
                                        "asynchronous":"0"])

    static func getToken(carno: String, timestamp: String) -> String {
        var jsonParam = Helper.basic_json_param
        jsonParam["carno"].string = carno
        jsonParam["timestamp"].string = timestamp
        
        var keyArray:[String] = []
        var token2bMD5 = ""
        for (key, _) in jsonParam {
            keyArray.append(key)
        }
        let sortedKey = keyArray.sorted(){$0 < $1}
        for key in sortedKey {
            if key == "auth_key" {continue}
            token2bMD5 += jsonParam[key].stringValue
        }
        token2bMD5 += self.secret_key
        return self.MD5(string: token2bMD5)
    }
    
    private static func MD5(string: String) -> String {
        var encodedString = ""
        let messageData = string.data(using:.utf8)!
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        
        let array = [UInt8](digestData)
        
        for byte in array {
            let val = byte & 0xff
            if Int(val) < 16 {
                encodedString.append("0")
            }
            let valStr = String(Int(val), radix:16, uppercase:false)
            encodedString += valStr
        }
        return encodedString
    }
}

extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
    
    /// Return hexadecimal string representation of NSData bytes
    var hexadecimalString: String {
        var bytes = [UInt8](repeating: 0, count: count)
        copyBytes(to: &bytes, count: count)
        
        let hexString = NSMutableString()
        for byte in bytes {
            hexString.appendFormat("%02x", UInt(byte))
        }
        return NSString(string: hexString) as String
    }
    
    // Return Data represented by this hexadecimal string
    static func fromHexString(string: String) -> Data {
        var data = Data(capacity: string.characters.count / 2)
        
        do {
            let regex = try NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
            regex.enumerateMatches(in: string, options: [], range: NSMakeRange(0, string.characters.count)) { match, _, _ in
                if let _match = match {
                    let byteString = (string as NSString).substring(with: _match.range)
                    if var num = UInt8(byteString, radix: 16) {
                        data.append(&num, count: 1)
                    }
                }
            }
        } catch {
        }
        
        return data
    }
}
