//
//  ViewController+Logger.swift
//  FreeOfo
//
//  Created by yunba on 2017/11/17.
//  Copyright © 2017年 yunba. All rights reserved.
//

import Foundation
import UIKit

extension ViewController {
    func logger(log: String, level:logLevel) {
//        let logLabel = UILabel(frame: CGRect(x: 0, y: ((self.logScrollView.subviews.count - 2) * 20), width: Int(self.logScrollView.bounds.width), height: 20))
        let logLabel = UILabel(frame: logScrollView.bounds)
        logLabel.numberOfLines = 0
        logLabel.lineBreakMode = .byTruncatingMiddle
//        logLabel.adjustsFontSizeToFitWidth = true
        logLabel.font = UIFont.systemFont(ofSize: 14.0)
        logLabel.text = log
        logLabel.sizeToFit()
        switch level {
        case .error:
            logLabel.textColor = .red
        case .info:
            logLabel.textColor = .white
        case .good:
            logLabel.textColor = .green
        }
        let offset = self.logScrollView.contentSize.height
        logLabel.frame = CGRect(x: 0, y: offset, width: logScrollView.bounds.size.width, height: logLabel.bounds.size.height)
        self.logScrollView.contentSize.height += logLabel.frame.size.height
        self.logScrollView.addSubview(logLabel)
        let bottomOffset = CGPoint(x: 0, y: logScrollView.contentSize.height - logScrollView.bounds.size.height)
        if !(logScrollView.contentOffset.y + logScrollView.bounds.size.height >= logScrollView.contentSize.height) {
            self.logScrollView.setContentOffset(bottomOffset, animated: true)
        }
    }
}

enum logLevel:Int {
    case error = 0
    case info  = 1
    case good  = 2
}
