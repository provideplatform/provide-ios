//
//  ReachabilityService.swift
//  provide
//
//  Created by Kyle Thomas on 10/25/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import Reachability

@objcMembers
class ReachabilityService {
    static let shared = ReachabilityService()

    private(set) var reachability: Reachability!

    private init() {
        reachability = Reachability.forInternetConnection()
        log()
    }

    func start() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(ReachabilityService.reachabilityChanged(_:)),
                                               name: NSNotification.Name.reachabilityChanged,
                                               object: nil)

        reachability.startNotifier()
    }

    func stop() {
        reachability.stopNotifier()

        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.reachabilityChanged,
                                                  object: nil)
    }

    @objc private func reachabilityChanged(_ notification: NSNotification) {
        log()
    }

    private func log() {
        if reachability.isReachable() {
            if reachability.isReachableViaWiFi() {
                logInfo("Internet is reachable via wifi radio")
                AnalyticsService.shared.track("Internet Reachable via WiFi", properties: ["timestamp": Date().utcString])
            } else if reachability.isReachableViaWWAN() {
                logInfo("Internet is reachable via cellular radio")
                AnalyticsService.shared.track("Internet Reachable via WWAN", properties: ["timestamp": Date().utcString])
            }
        } else {
            logWarn("Internet is not reachable")
            AnalyticsService.shared.track("Internet Unreachable", properties: ["timestamp": Date().utcString])
        }
    }
}
