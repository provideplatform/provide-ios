//
//  AnalyticsService.swift
//  provide
//
//  Created by Kyle Thomas on 5/21/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class AnalyticsService: NSObject {

    private var analyticsEnabled: Bool {
        return !isSimulator() && !(isRunningUnitTests() || isRunningKIFTests())
    }

    private static let sharedInstance = AnalyticsService()

    class func sharedService() -> AnalyticsService {
        return sharedInstance
    }

    override init() {
        super.init()

        swizzleMethodSelector("viewDidAppear:", withSelector: "swizzled_viewDidAppear:", forClass: UIViewController.self)

        if analyticsEnabled {
            let configuration = SEGAnalyticsConfiguration(writeKey: "7c9wf6cpxb")
            //SEGAnalytics.debug(true)
            configuration.flushAt = 1
            log("Segment.io enabled with version \(SEGAnalytics.version())")
            SEGAnalytics.setupWithConfiguration(configuration)
        }
    }

    // MARK: Analytics session management

    func identify(user: User) {
        if analyticsEnabled {
            let analytics = SEGAnalytics.sharedAnalytics()
            log("Analytics Identify: User id = \(user.id)")
            analytics.identify("\(user.id)", traits: user.toDictionary())
        }
    }

    func logout() {
        if analyticsEnabled {
            SEGAnalytics.sharedAnalytics().reset()
        }
    }

    // MARK: Event tracking methods

    func track(event: String) {
        track(event, properties: nil, options: nil)
    }

    func track(event: String, properties: [String : AnyObject]) {
        track(event, properties: properties, options: nil)
    }

    func track(event: String!, properties: [String : AnyObject]!, options: [String : AnyObject]! = nil) {
        if analyticsEnabled {
            var message = "Track: \(event)"
            if let populatedProperties = properties {
                message += "\nproperties = \(populatedProperties)"
            }
            log(message)
            SEGAnalytics.sharedAnalytics().track(event, properties: properties, options: options)
        }
    }

    // MARK: UI event tracking methods

    func screen(screenTitle: String) {
        screen(screenTitle, properties: nil, options: nil)
    }

    func screen(screenTitle: String, properties: [String : AnyObject]) {
        screen(screenTitle, properties: properties, options: nil)
    }

    func screen(screenTitle: String, properties: [String : AnyObject]!, options: [String : AnyObject]!) {
        if analyticsEnabled {
            var message = "Screen: \(screenTitle)"
            if let populatedProperties = properties {
                message += "\nproperties = \(populatedProperties)"
            }
            log(message)
            SEGAnalytics.sharedAnalytics().screen(screenTitle, properties: properties, options: options)
        }
    }

    func viewDidAppearForController(controller: UIViewController, animated: Bool) {
        if analyticsEnabled {
            let className = classNameForObject(controller)

            if shouldIgnoreViewController(className) == false {
                screen(className)
            }
        }
    }

    private func shouldIgnoreViewController(className: String) -> Bool {
        let prefixes = ["UI", "_", "DD", "MK"]
        for prefix in prefixes {
            if className.hasPrefix(prefix) {
                return true
            }
        }

        return false
    }
}
