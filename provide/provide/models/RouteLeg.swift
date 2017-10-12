//
//  RouteLeg.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

@objcMembers
class RouteLeg: Model {

    private var distanceInMeters: Double = 0
    private(set) var duration: Double = 0
    private(set) var steps = [RouteLegStep]()

    var currentStepIndex: Int = 0

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "length": "distanceInMeters",
            "travelTime": "duration",
        ])
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "maneuver", toKeyPath: "steps", with: RouteLegStep.mapping()))
        return mapping!
    }

    private var distance: CLLocationDistance {
        return distanceInMeters
    }

    private var distanceInMiles: Double {
        return distance * 0.000621371
    }

    private var distanceInFeet: CLLocationDistance {
        return distanceInMiles * 5820.0
    }

    private var distancePerStep: CLLocationDistance {
        return distance / Double(steps.count)
    }

    var distanceString: String {
        if distanceInMiles > 0.1 {
            return String(format: "%.1f", distanceInMiles) + " mi"
        } else {
            return String(format: "%.0f", ceil(distanceInFeet)) + " ft"
        }
    }

    var durationString: String {
        return "\(etaMinutes) min"
    }

    private var etaMinutes: Int {
        let minutes = duration / 60
        return Int(round(minutes))
    }

    private var isFinished: Bool {
        return currentStepIndex == steps.count - 1
    }

    var currentStep: RouteLegStep! {
        var step: RouteLegStep!
        if currentStepIndex <= steps.count - 1 {
            step = steps[currentStepIndex]
        }
        return step
    }

    var nextStep: RouteLegStep! {
        var step: RouteLegStep!
        let nextStepIndex = currentStepIndex + 1
        if nextStepIndex <= steps.count - 1 {
            step = steps[nextStepIndex]
        }
        return step
    }
}
