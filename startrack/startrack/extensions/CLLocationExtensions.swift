//
//  CLLocationExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 7/15/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import CoreLocation

let timeIntervalSinceThreshold: Double = 1.0
let horizontalAccuracyThreshold: Double = 10.0
let verticalAccuracyThreshold: Double = 10.0
let earthRadiusInMiles = 3964.037911746

extension CLLocation {

    var isAccurate: Bool {
        return realTime && horizontallyAccurate && verticallyAccurate && validSpeed
    }

    private var realTime: Bool {
        return abs(timestamp.timeIntervalSinceNow) < timeIntervalSinceThreshold
    }

    private var horizontallyAccurate: Bool {
        return horizontalAccuracy >= 0.0 && horizontalAccuracy <= horizontalAccuracyThreshold
    }

    private var verticallyAccurate: Bool {
        return (verticalAccuracy >= 0.0 && verticalAccuracy <= verticalAccuracyThreshold) || isSimulator()
    }

    private var validSpeed: Bool {
        return speed >= 0.0 || isSimulator()
    }
}
