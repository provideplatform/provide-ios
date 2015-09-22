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
            return barCodeImageWithData(data!, filter: filter)
        }
        return nil
    }

    class func barCodeImageWithData(data: NSData, filter: CIFilter) -> UIImage! {
        filter.setValue(data, forKey: "inputMessage")
        let context = CIContext(options: nil)
        let outputImage = filter.outputImage!.imageByApplyingTransform(CGAffineTransformMakeScale(100.0, 100.0))
        let cgImage = context.createCGImage(outputImage, fromRect: outputImage.extent)
        return UIImage(CGImage: cgImage)
    }

    func resize(rect: CGRect) -> UIImage! {
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        drawInRect(rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}
