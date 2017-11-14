//
//  NetService.swift
//  FreeOfo
//
//  Created by yunba on 2017/11/9.
//  Copyright © 2017年 yunba. All rights reserved.
//

import Foundation
import Moya
import SwiftyJSON

enum OfoReq {
    case get_with_url_lock(token:String, carno:String)
    case query_info(lockSn: String)
}

//MARK: - provider target
extension OfoReq:TargetType{
    var baseURL: URL {return URL(string:"http://twxworker.ofo.com")!}
    var path: String{
        switch self {
        case .get_with_url_lock(_,_):
            return "/lockWorker/querySnByCarno"
        case .query_info(_):
            return "/twxworker/queryInfo"
        }
    }
    var method: Moya.Method {
        switch self {
        case .get_with_url_lock(_,_):
            return .get
        case .query_info(lockSn: _):
            return .get
        }
    }
    var task: Task {
        switch self {
        case .get_with_url_lock(token: let token, carno: let carno):
            var params = Helper.basic_json_param.dictionaryObject!
            params["token"] = token
            params["carno"] = carno
            return .requestParameters(parameters: params,
                                      encoding: URLEncoding.queryString)
        case .query_info(lockSn: let lockSn):
            return .requestParameters(parameters: ["lock_sn": lockSn], encoding: URLEncoding.queryString)
        }
    }
    var sampleData: Data {
        switch self {
        case .get_with_url_lock(_,_):
            return "".utf8Encoded
        case .query_info(lockSn: _):
            return "".utf8Encoded
        }
    }
    var headers: [String: String]? {
        switch self {
        case .get_with_url_lock(token: _, carno: _):
            return nil
        case .query_info(lockSn: _):
            return nil
        }
    }
}

//MARK: - string helper
private extension String {
    var urlEscaped: String {
        return addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }

    var utf8Encoded: Data {
        return data(using: .utf8)!
    }
}
