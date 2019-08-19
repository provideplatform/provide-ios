//
//  Color.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import UIKit

class Color {

    class func darkBlueBackground() -> UIColor {
        return UIColor("#120b29") // "haiti"
    }

    class func applicationDefaultBackgroundImage() -> UIImage {
        return UIImage("background")
    }

    class func applicationDefaultNavigationBarBackgroundColor() -> UIColor {
        return .clear //UIColor("#3983f2")
    }

    class func authenticationViewControllerButtonColor() -> UIColor {
        return .white
    }

    class func applicationDefaultBarTintColor() -> UIColor {
        return darkBlueBackground()
    }

    class func applicationDefaultBarButtonItemTintColor() -> UIColor {
        return .white
    }

    class func pinInputControlBoxBorderColor() -> UIColor {
        return UIColor(red: 0.58, green: 0.72, blue: 0.84, alpha: 1.0)
    }

    class func annotationViewBackgroundImage() -> UIImage {
        return applicationDefaultBackgroundImage()
    }

    class func polylineStrokeColor() -> UIColor {
        return UIColor("1C133A") // purple
    }

    class func warningBackground() -> UIColor {
        return UIColor("#FC3A57") // radicalRed
    }

    class func awaitingScheduleStatusColor() -> UIColor {
        return UIColor("#9D98CB") // blueBell
    }

    class func scheduledStatusColor() -> UIColor {
        return UIColor("#5B20F2") // electricIndigo
    }

    class func enRouteStatusColor() -> UIColor {
        return UIColor("#F459F4") // pinkFlamingo
    }

    class func inProgressStatusColor() -> UIColor {
        return UIColor("#AE30FF") // electricViolet
    }

    class func canceledStatusColor() -> UIColor {
        return UIColor("#F459F4") // pinkFlamingo
    }

    class func pendingCompletionStatusColor() -> UIColor {
        return UIColor("#EEECFB") // moonRaker
    }

    class func completedStatusColor() -> UIColor {
        return UIColor("#00b050")
    }
}
