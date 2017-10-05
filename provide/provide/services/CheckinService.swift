//
//  CheckinService.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import KTSwiftExtensions

class CheckinService: NSObject {

    let defaultCheckinTimeInterval: TimeInterval = 300
    let navigationCheckinTimeInterval: TimeInterval = 10

    fileprivate var checkinTimeInterval: TimeInterval! {
        didSet {
            if let oldInterval = oldValue {
                if oldInterval != checkinTimeInterval {
                    restart()
                }
            }
        }
    }

    fileprivate var timer: Timer!

    required override init() {
        super.init()

        checkinTimeInterval = defaultCheckinTimeInterval
    }

    fileprivate static let sharedInstance = CheckinService()

    class func sharedService() -> CheckinService {
        return sharedInstance
    }

    // MARK: Navigation accuracy

    func enableNavigationAccuracy() {
        setCheckinTimeInterval(navigationCheckinTimeInterval)
    }

    func disableNavigationAccuracy() {
        setCheckinTimeInterval(defaultCheckinTimeInterval)
    }

    // MARK: Checkin frequency

    func setCheckinTimeInterval(_ checkinTimeInterval: TimeInterval) {
        self.checkinTimeInterval = checkinTimeInterval
    }

    // MARK: Start/stop checkins

    func start() {
        restart()
        logInfo("Started checkin service")
    }

    func stop() {
        if let t = timer {
            t.invalidate()
            timer = nil
        }
        
        logInfo("Stopped checkin service")
    }

    func checkin() {
        LocationService.sharedService().resolveCurrentLocationAndHeading { location, heading in
            ApiService.sharedService().checkin(location, heading: heading)
            LocationService.sharedService().background()
        }
    }

    fileprivate func restart() {
        stop()

        if let timer = timer {
            timer.invalidate()
            self.timer = nil
        }

        timer = Timer.scheduledTimer(timeInterval: checkinTimeInterval, target: self, selector: #selector(checkin), userInfo: nil, repeats: true)
    }
}
