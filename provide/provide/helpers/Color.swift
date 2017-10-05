//
//  Color.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class Color {

    class func menuBackgroundColor() -> UIColor {
        return darkBlueBackground()
    }

    class func darkBlueBackground() -> UIColor {
        return UIColor("#202838")
    }

    class func applicationDefaultBackgroundImage() -> UIImage {
        return UIImage("background")
    }

    class func applicationDefaultNavigationBarBackgroundImage() -> UIImage {
        return UIImage("bar-background")
    }

    class func applicationDefaultNavigationBarBackgroundColor() -> UIColor {
        return .clear //UIColor("#3983f2")
    }

    class func authenticationViewControllerButtonColor() -> UIColor {
        return UIColor("#3983f2")
    }

    class func applicationDefaultBarTintColor() -> UIColor {
        return darkBlueBackground()
    }

    class func applicationDefaultBarButtonItemTintColor() -> UIColor {
        return darkBlueBackground()
    }

    class func applicationDefaultBackgroundImageColor(_ rect: CGRect) -> UIColor {
        return .resizedColorWithPatternImage(applicationDefaultBackgroundImage(), rect: rect)
    }

    class func pinInputControlBoxBorderColor() -> UIColor {
        return UIColor(red: 0.58, green: 0.72, blue: 0.84, alpha: 1.0)
    }

    class func annotationViewBackgroundImage() -> UIImage {
        return applicationDefaultBackgroundImage()
    }

    class func annotationViewBackgroundImageColor() -> UIColor {
        return UIColor(patternImage: annotationViewBackgroundImage()).withAlphaComponent(0.75)
    }

    class func annotationViewBackgroundSelectedImageColor() -> UIColor {
        return UIColor(patternImage: annotationViewBackgroundImage()).withAlphaComponent(1.0)
    }

    class func polylineStrokeColor() -> UIColor {
        return UIColor(red: 0.392, green: 0.706, blue: 0.820, alpha: 1.0)
    }

    class func confirmationGreenBackground() -> UIColor {
        return UIColor(red: 0.369, green: 0.843, blue: 0.365, alpha: 1.00)
    }

    class func warningBackground() -> UIColor {
        return UIColor(red: 0.737, green: 0.267, blue: 0.192, alpha: 1.00)
    }

    class func directionIndicatorBorderColor() -> UIColor {
        return UIColor("#70d1f0")
    }

    class func awaitingScheduleStatusColor() -> UIColor {
        return UIColor("#0070c0")
    }

    class func scheduledStatusColor() -> UIColor {
        return UIColor("#0070c0")
    }

    class func enRouteStatusColor() -> UIColor {
        return UIColor("#ffc000")
    }

    class func loadingStatusColor() -> UIColor {
        return UIColor("#ffc000")
    }

    class func unloadingStatusColor() -> UIColor {
        return UIColor("#ffc000")
    }

    class func inProgressStatusColor() -> UIColor {
        return UIColor("#ffc000")
    }

    class func canceledStatusColor() -> UIColor {
        return UIColor("#ff0000")
    }

    class func abandonedStatusColor() -> UIColor {
        return UIColor("#ff0000")
    }

    class func pendingCompletionStatusColor() -> UIColor {
        return UIColor("#ffff00")
    }

    class func completedStatusColor() -> UIColor {
        return UIColor("#00b050")
    }
}
