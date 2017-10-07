//
//  CheckinService.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

class CheckinService: NSObject {
    static let shared = CheckinService()

    let defaultCheckinTimeInterval: TimeInterval = 300
    let navigationCheckinTimeInterval: TimeInterval = 10

    private var checkinTimeInterval: TimeInterval! {
        didSet {
            if let oldInterval = oldValue, oldInterval != checkinTimeInterval {
                restart()
            }
        }
    }

    private var timer: Timer!

    required override init() {
        super.init()

        checkinTimeInterval = defaultCheckinTimeInterval
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

    @objc func checkin() {
        LocationService.shared.resolveCurrentLocationAndHeading { location, heading in
            ApiService.shared.checkin(location, heading: heading)
            LocationService.shared.background()
        }
    }

    private func restart() {
        stop()

        if let timer = timer {
            timer.invalidate()
            self.timer = nil
        }

        timer = Timer.scheduledTimer(timeInterval: checkinTimeInterval, target: self, selector: #selector(checkin), userInfo: nil, repeats: true)
    }
}
