//
//  AnalyticsService.swift
//  provide
//
//  Created by Kyle Thomas on 5/21/15.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import Foundation

class AnalyticsService: NSObject {
    static let shared = AnalyticsService()

    private var analyticsEnabled: Bool {
        return !isSimulator() && !isRunningUnitTests()
    }

    override init() {
        super.init()

        swizzleMethodSelector("viewDidAppear:", withSelector: "swizzled_viewDidAppear:", forClass: UIViewController.self)

        if analyticsEnabled {
//            let configuration = SEGAnalyticsConfiguration(writeKey: "BsyhXoiZ05nMBittF2CKM2DEEpUfOExT")
//            //SEGAnalytics.debug(true)
//            configuration.flushAt = 1
//            log("Segment.io enabled with version \(SEGAnalytics.version())")
//            SEGAnalytics.setup(with: configuration)
        }
    }

    // MARK: Analytics session management

    func identify(_ user: User) {
        if analyticsEnabled {
//            let analytics = SEGAnalytics.shared()
//            log("Analytics Identify: User id = \(user.id)")
//            analytics.identify("\(user.id)", traits: user.toDictionary())
        }
    }

    func logout() {
        if analyticsEnabled {
//            SEGAnalytics.shared().reset()
        }
    }

    // MARK: Event tracking methods

    func track(_ event: String) {
        track(event, properties: nil, options: nil)
    }

    private func track(_ event: String, properties: [String: Any]) {
        track(event, properties: properties, options: nil)
    }

    func track(_ event: String, properties: [String: Any]?, options: [String: Any]? = nil) {
        if analyticsEnabled {
            var message = "Track: \(event)"
            if let populatedProperties = properties {
                message += "\nproperties = \(populatedProperties)"
            }
            log(message)
//            SEGAnalytics.shared().track(event, properties: properties, options: options)
        }
    }

    // MARK: UI event tracking methods

    private func screen(_ screenTitle: String) {
        screen(screenTitle, properties: nil, options: nil)
    }

    private func screen(_ screenTitle: String, properties: [String: Any]) {
        screen(screenTitle, properties: properties, options: nil)
    }

    private func screen(_ screenTitle: String, properties: [String: Any]?, options: [String: Any]?) {
        if analyticsEnabled {
            var message = "Screen: \(screenTitle)"
            if let populatedProperties = properties {
                message += "\nproperties = \(populatedProperties)"
            }
            log(message)
//            SEGAnalytics.shared().screen(screenTitle, properties: properties, options: options)
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

    private func shouldIgnoreViewController(_ className: String) -> Bool {
        let prefixes = ["UI", "_", "DD", "MK"]
        for prefix in prefixes {
            if className.hasPrefix(prefix) {
                return true
            }
        }

        return false
    }
}
