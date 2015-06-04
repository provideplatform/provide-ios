//
//  UIColorExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

extension UIColor {

    convenience init(_ hexString: String) {
        var rgb: UInt32 = 0
        var scanner = NSScanner(string: hexString)
        scanner.scanLocation = 1
        scanner.scanHexInt(&rgb)

        self.init(red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(rgb & 0x0000FF) / 255.0,
                  alpha: 1.0)
    }

    class func resizedColorWithPatternImage(patternImage: UIImage!, rect: CGRect) -> UIColor! {
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        patternImage.drawInRect(rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return UIColor(patternImage: resizedImage)
    }
}
