//
//  AppearenceProxy.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class AppearenceProxy {

    class func setup() {
        UINavigationBar.appearance().tintColor = defaultBarTintColor()
        UINavigationBar.appearance().titleTextAttributes = navBarTitleTextAttributes()

        UIBarButtonItem.appearance().tintColor = defaultBarTintColor()
        UIBarButtonItem.appearance().setTitleTextAttributes(barButtonItemTitleTextAttributes(), forState: .Normal)

        UITabBar.appearance().tintColor = defaultBarTintColor()
        UITabBarItem.appearance().setTitleTextAttributes(barButtonItemTitleTextAttributes(), forState: .Normal)

        UIToolbar.appearance().tintColor = defaultBarTintColor()
    }

    class func defaultBarTintColor() -> UIColor {
        return UIColor.whiteColor()
    }

    class func navBarTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 20)!,
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]
    }

    class func inProgressBarButtonItemTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Bold", size: 14)!,
            NSForegroundColorAttributeName : Color.inProgressStatusColor()
        ]
    }

    class func cancelBarButtonItemTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 14)!,
            NSForegroundColorAttributeName : Color.canceledStatusColor()
        ]
    }

    class func barButtonItemTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 14)!,
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]
    }

    class func selectedButtonItemTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Bold", size: 14)!,
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]
    }

    class func barButtonItemDisabledTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 14)!,
            NSForegroundColorAttributeName : UIColor.darkGrayColor()
        ]
    }
}
