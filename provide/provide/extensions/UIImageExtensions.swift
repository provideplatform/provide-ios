//
//  UIImageExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

extension UIImage {
    convenience init!(_ imageName: String) {
        self.init(named: imageName)
    }

    class func imageFromDataURL(dataURL: NSURL) -> UIImage! {
        if let data = NSData(contentsOfURL: dataURL) {
            return UIImage(data: data)
        }
        return nil
    }

    func crop(rect: CGRect) -> UIImage! {
        let image = CGImageCreateWithImageInRect(CGImage, rect)!
        return UIImage(CGImage: image)
    }
    
    func resize(rect: CGRect) -> UIImage! {
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        drawInRect(rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }

    func scaledToWidth(width: CGFloat) -> UIImage! {
        let originalWidth = self.size.width
        let scale = width / originalWidth
        let height = self.size.height * scale
        let width = originalWidth * scale

        let rect = CGRect(x: 0.0, y: 0.0, width: width, height: height)
        let size = rect.size

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        drawInRect(rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}
