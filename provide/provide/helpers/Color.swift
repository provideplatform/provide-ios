//
//  Color.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class Color {

    class func menuBackgroundColor() -> UIColor {
        return UIColor(red: 0.969, green: 0.965, blue: 0.949, alpha: 1.0)
    }

    class func darkBlueBackground() -> UIColor {
        return UIColor(red: 0.008, green: 0.067, blue: 0.231, alpha: 1.00)
    }

    class func applicationDefaultBackgroundImage() -> UIImage {
        return UIImage("navbar-background")
    }

    class func applicationDefaultBackgroundImageColor(rect: CGRect) -> UIColor {
        return UIColor.resizedColorWithPatternImage(applicationDefaultBackgroundImage(), rect: rect)
    }

    class func annotationViewBackgroundImage() -> UIImage {
        return applicationDefaultBackgroundImage()
    }

    class func annotationViewBackgroundImageColor() -> UIColor {
        return UIColor(patternImage: annotationViewBackgroundImage()).colorWithAlphaComponent(0.75)
    }

    class func annotationViewBackgroundSelectedImageColor() -> UIColor {
        return UIColor(patternImage: annotationViewBackgroundImage()).colorWithAlphaComponent(1.0)
    }
}
