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
        let logLabel = UILabel(frame: CGRect(x: 0, y: ((self.logScrollView.subviews.count - 2) * 20), width: Int(self.logScrollView.bounds.width), height: 20))
        logLabel.numberOfLines = 14
        logLabel.lineBreakMode = .byTruncatingMiddle
        logLabel.text = log
        switch level {
        case .error:
            logLabel.textColor = .red
        case .info:
            logLabel.textColor = .white
        case .good:
            logLabel.textColor = .green
        }
        logLabel.font = UIFont.systemFont(ofSize: 14.0)
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
