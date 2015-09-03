//
//  UIBarButtonItem.swift
//  provide
//
//  Created by Jawwad Ahmad on 6/24/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

extension UIBarButtonItem {
    class func plainBarButtonItem(title title: String, target: AnyObject, action: Selector) -> UIBarButtonItem {
        let barButtonItem = UIBarButtonItem(title: title, style: .Plain, target: target, action: action)
        barButtonItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        barButtonItem.setTitleTextAttributes(AppearenceProxy.barButtonItemDisabledTitleTextAttributes(), forState: .Disabled)
        return barButtonItem
    }
}
