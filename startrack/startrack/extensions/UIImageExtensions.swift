//
//  UIImageExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit
import CoreImage

extension UIImage {
    convenience init!(_ imageName: String) {
        self.init(named: imageName)
    }

    class func qrCodeImageWithString(string: String) -> UIImage! {
        return barCodeImageWithString(string, filterWithName: "CIQRCodeGenerator")
    }

    class func barCodeImageWithString(string: String, filterWithName filterName: String) -> UIImage! {
        let data = string.dataUsingEncoding(NSASCIIStringEncoding)
        if let filter = CIFilter(name: filterName) {
            filter.setValue(data, forKey: "inputMessage")
            return UIImage(CIImage: filter.outputImage!)
        }
        return nil
    }

    func resize(rect: CGRect) -> UIImage! {
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        drawInRect(rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}
