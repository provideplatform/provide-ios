//
//  SimulatedCLHeading.swift
//  provide
//
//  Created by Kyle Thomas on 9/3/17.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import Foundation

class SimulatedHeading: CLHeading {

    override var timestamp: Date {
        return Date()
    }

    override var headingAccuracy: CLLocationDirection {
        return 0
    }

    override var magneticHeading: CLLocationDirection {
        return 0
    }
}
