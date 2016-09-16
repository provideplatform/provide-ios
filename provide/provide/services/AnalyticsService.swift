//
//  AnalyticsService.swift
//  provide
//
//  Created by Kyle Thomas on 5/21/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import Analytics
import KTSwiftExtensions

class AnalyticsService: NSObject {

    fileprivate var analyticsEnabled: Bool {
        return !isSimulator() && !isRunningUnitTests()
    }

    fileprivate static let sharedInstance = AnalyticsService()

    class func sharedService() -> AnalyticsService {
        return sharedInstance
    }

    override init() {
        super.init()

        swizzleMethodSelector("viewDidAppear:", withSelector: "swizzled_viewDidAppear:", forClass: UIViewController.self)

        if analyticsEnabled {
            let configuration = SEGAnalyticsConfiguration(writeKey: "7c9wf6cpxb")
            //SEGAnalytics.debug(true)
            configuration?.flushAt = 1
            log("Segment.io enabled with version \(SEGAnalytics.version())")
            SEGAnalytics.setup(with: configuration)
        }
    }

    // MARK: Analytics session management

    func identify(_ user: User) {
        if analyticsEnabled {
            let analytics = SEGAnalytics.shared()
            log("Analytics Identify: User id = \(user.id)")
            analytics?.identify("\(user.id)", traits: user.toDictionary())
        }
    }

    func logout() {
        if analyticsEnabled {
            SEGAnalytics.shared().reset()
        }
    }

    // MARK: Event tracking methods

    func track(_ event: String) {
        track(event, properties: nil, options: nil)
    }

    func track(_ event: String, properties: [String : AnyObject]) {
        track(event, properties: properties, options: nil)
    }

    func track(_ event: String, properties: [String : AnyObject]?, options: [String : AnyObject]? = nil) {
        if analyticsEnabled {
            var message = "Track: \(event)"
            if let populatedProperties = properties {
                message += "\nproperties = \(populatedProperties)"
            }
            log(message)
            SEGAnalytics.shared().track(event, properties: properties, options: options)
        }
    }

    // MARK: UI event tracking methods

    func screen(_ screenTitle: String) {
        screen(screenTitle, properties: nil, options: nil)
    }

    func screen(_ screenTitle: String, properties: [String : AnyObject]) {
        screen(screenTitle, properties: properties, options: nil)
    }

    func screen(_ screenTitle: String, properties: [String : AnyObject]?, options: [String : AnyObject]?) {
        if analyticsEnabled {
            var message = "Screen: \(screenTitle)"
            if let populatedProperties = properties {
                message += "\nproperties = \(populatedProperties)"
            }
            log(message)
            SEGAnalytics.shared().screen(screenTitle, properties: properties, options: options)
        }
    }

    func viewDidAppearForController(_ controller: UIViewController, animated: Bool) {
        if analyticsEnabled {
            let className = classNameForObject(controller)

            if !shouldIgnoreViewController(className) {
                screen(className)
            }
        }
    }

    fileprivate func shouldIgnoreViewController(_ className: String) -> Bool {
        let prefixes = ["UI", "_", "DD", "MK"]
        for prefix in prefixes {
            if className.hasPrefix(prefix) {
                return true
            }
        }

        return false
    }
}
