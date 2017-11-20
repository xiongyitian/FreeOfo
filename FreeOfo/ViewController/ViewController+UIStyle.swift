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
        self.setBackgroundColor(color: UIColor(hex:"1AAD19"), forState: .normal)
        self.setBackgroundColor(color: UIColor(hex:"AAAAAA"), forState: .disabled)
        self.clipsToBounds = true
        if (isCircle) {
            self.layer.cornerRadius = 0.5 * self.bounds.size.width
        }
        closure(self)
    }
    
    func setBackgroundColor(color: UIColor, forState: UIControlState) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()!.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()!.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.setBackgroundImage(colorImage, for: forState)
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

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
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
