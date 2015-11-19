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

    class func cancelBarButtonItemTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 14)!,
            NSForegroundColorAttributeName : UIColor.redColor()
        ]
    }

    class func barButtonItemTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 14)!,
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
