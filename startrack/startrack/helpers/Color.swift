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
        return UIColor("#2388DB") //UIColor(red: 0.969, green: 0.965, blue: 0.949, alpha: 1.0)
    }

    class func darkBlueBackground() -> UIColor {
        return UIColor("#2388DB") //UIColor(red: 0.008, green: 0.067, blue: 0.231, alpha: 1.00)
    }

    class func applicationDefaultBackgroundImage() -> UIImage {
        return windowBounds().size.width > 414.0 ? UIImage("background-lg") : UIImage("background")
    }

    class func applicationDefaultNavigationBarBackgroundImage() -> UIImage {
        return UIImage("bar-background")
    }

    class func applicationDefaultBackgroundImageColor(rect: CGRect) -> UIColor {
        return UIColor("#2388DB") //UIColor.resizedColorWithPatternImage(applicationDefaultBackgroundImage(), rect: rect)
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

    class func polylineStrokeColor() -> UIColor {
        return UIColor(red: 0.392, green: 0.706, blue: 0.820, alpha: 1.0)
    }

    class func directionIndicatorBorderColor() -> UIColor {
        return UIColor("#70d1f0")
    }

    class func scheduledStatusColor() -> UIColor {
        return UIColor("#ffffff")
    }

    class func enRouteStatusColor() -> UIColor {
        return UIColor("#dff0d8")
    }

    class func loadingStatusColor() -> UIColor {
        return UIColor("#dff0d8")
    }

    class func unloadingStatusColor() -> UIColor {
        return UIColor("#dff0d8")
    }

    class func inProgressStatusColor() -> UIColor {
        return UIColor("#dff0d8")
    }

    class func canceledStatusColor() -> UIColor {
        return UIColor("#fdc554")
    }

    class func abandonedStatusColor() -> UIColor {
        return UIColor("#ff503f")
    }

    class func pendingCompletionStatusColor() -> UIColor {
        return UIColor("#f89406")
    }

    class func completedStatusColor() -> UIColor {
        return UIColor("#dff0d8")
    }
}