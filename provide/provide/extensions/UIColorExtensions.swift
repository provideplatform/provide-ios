//
//  UIColorExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

extension UIColor {

    class func resizedColorWithPatternImage(patternImage: UIImage!, rect: CGRect) -> UIColor! {
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        patternImage.drawInRect(rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return UIColor(patternImage: resizedImage)
    }
}
