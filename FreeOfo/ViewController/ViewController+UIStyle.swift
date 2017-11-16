//
//  ButtonStyle.swift
//  FreeOfo
//
//  Created by yunba on 2017/11/9.
//  Copyright © 2017年 yunba. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    func addWithStyle(isCircle: Bool=true, title: String, backgroundColor: UIColor, closure:(UIButton) -> Void) {
        self.setTitle(title, for: .normal)
        self.backgroundColor = backgroundColor
        self.clipsToBounds = true
        if (isCircle) {
            self.layer.cornerRadius = 0.5 * self.bounds.size.width
        }
        closure(self)
    }
}

extension UITextField {
    func setBottomBorder() {
        self.borderStyle = .none
        self.layer.backgroundColor = UIColor.white.cgColor
        
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 0.0
    }
}

extension ViewController {
    func getLogLabel(log: String) -> UILabel {
        let logLabel = UILabel(frame: CGRect(x: 0, y: ((self.logScrollView.subviews.count - 2) * 40), width: Int(self.logScrollView.bounds.width), height: 40))
        print(self.logScrollView.subviews.count)
        logLabel.numberOfLines = 14
        logLabel.lineBreakMode = .byTruncatingMiddle
        logLabel.text = log
        logLabel.textColor = .white
        logLabel.font = UIFont.systemFont(ofSize: 14.0)
        
        return logLabel
    }
}
