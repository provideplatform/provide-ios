//
//  AppearenceProxy.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class AppearenceProxy {

    class func setup() {
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().backgroundColor = Color.applicationDefaultNavigationBarBackgroundColor()
        UINavigationBar.appearance().tintColor = nil
        UINavigationBar.appearance().titleTextAttributes = navBarTitleTextAttributes()

        UIBarButtonItem.appearance().tintColor = defaultBarTintColor()
        UIBarButtonItem.appearance().setTitleTextAttributes(barButtonItemTitleTextAttributes(), for: UIControlState())

        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIToolbar.self]).tintColor = UIColor.white
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIToolbar.self]).setTitleTextAttributes(whiteButtonItemTitleTextAttributes(), for: UIControlState())

        UITabBar.appearance().tintColor = defaultBarTintColor()
        UITabBarItem.appearance().setTitleTextAttributes(barButtonItemTitleTextAttributes(), for: UIControlState())

        UIToolbar.appearance().tintColor = defaultBarTintColor()
    }

    class func defaultBarTintColor() -> UIColor {
        return Color.applicationDefaultBarTintColor()
    }

    class func navBarTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 20)!,
            NSForegroundColorAttributeName : Color.darkBlueBackground()
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

    class func whiteButtonItemTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 14)!,
            NSForegroundColorAttributeName : UIColor.white
        ]
    }

    class func barButtonItemTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 14)!,
            NSForegroundColorAttributeName : Color.darkBlueBackground()
        ]
    }

    class func selectedButtonItemTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Bold", size: 14)!,
            NSForegroundColorAttributeName : Color.darkBlueBackground()
        ]
    }

    class func barButtonItemDisabledTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 14)!,
            NSForegroundColorAttributeName : UIColor.darkGray
        ]
    }
}
