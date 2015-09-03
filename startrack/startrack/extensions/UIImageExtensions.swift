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

    func resize(rect: CGRect) -> UIImage! {
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        drawInRect(rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}
