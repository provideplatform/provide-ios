//
//  NSNotificationCenterExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

extension NSNotificationCenter {

    func postNotificationName(aName: String) {
        postNotificationName(aName, object: nil)
    }

    func addObserver(observer: AnyObject, selector: Selector, name: String?) {
        addObserver(observer, selector: selector, name: name, object: nil)
    }

    func addObserverForName(name: String?, queue: NSOperationQueue? = nil, usingBlock block: (NSNotification!) -> Void) {
        addObserverForName(name, object: nil, queue: queue, usingBlock: block)
    }
}
