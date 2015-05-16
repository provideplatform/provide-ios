//
//  UIImageExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

extension UIImage {

    class func imageFromBase64EncodedString(base64EncodedString: String) -> UIImage? {
        var image : UIImage!
        if let decodedData = NSData(base64EncodedString: base64EncodedString, options: .allZeros) {
            image = UIImage(data: decodedData)
        }
        return image
    }

}
