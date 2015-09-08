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
        UIBarButtonItem.appearance().setTitleTextAttributes(navBarTitleTextAttributes(), forState: .Normal)
    }

    class func navBarTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 20)!,
            NSForegroundColorAttributeName : Color.darkBlueBackground()
        ]
    }

    class func barButtonItemTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 14)!,
            NSForegroundColorAttributeName : Color.darkBlueBackground()
        ]
    }

    class func barButtonItemDisabledTitleTextAttributes() -> [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 14)!,
            NSForegroundColorAttributeName : UIColor.darkGrayColor()
        ]
    }
}
