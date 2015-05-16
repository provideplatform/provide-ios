//
//  CheckinService.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class CheckinService: NSObject {

    let defaultCheckinTimeInterval = 300 as NSTimeInterval
    let navigationCheckinTimeInterval = 10 as NSTimeInterval

    private var checkinTimeInterval: NSTimeInterval! {
        didSet {
            if let oldInterval = oldValue {
                if oldInterval != checkinTimeInterval {
                    restart()
                }
            }
        }
    }

    private var timer: NSTimer!

    required override init() {
        super.init()

        checkinTimeInterval = defaultCheckinTimeInterval
    }

    class func sharedService() -> CheckinService {
        struct Static {
            static let instance = CheckinService()
        }
        return Static.instance
    }

    // MARK: Navigation accuracy

    func enableNavigationAccuracy() {
        setCheckinTimeInterval(navigationCheckinTimeInterval)
    }

    func disableNavigationAccuracy() {
        setCheckinTimeInterval(defaultCheckinTimeInterval)
    }

    // MARK: Checkin frequency

    func setCheckinTimeInterval(checkinTimeInterval: NSTimeInterval) {
        self.checkinTimeInterval = checkinTimeInterval
    }

    // MARK: Start/stop checkins

    func start() {
        restart()
    }

    func stop() {
        if let t = timer {
            t.invalidate()
            timer = nil
        }
    }

    func checkin() {
        LocationService.sharedService().resolveCurrentLocation({ (location: CLLocation) -> () in
            ApiService.sharedService().checkin(location)
            LocationService.sharedService().background()
        })
    }

    private func restart() {
        stop()

        timer = NSTimer.scheduledTimerWithTimeInterval(checkinTimeInterval, target: self, selector: "checkin", userInfo: nil, repeats: true)
        timer.fire()
    }
}
