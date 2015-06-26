//
//  RouteLeg.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class RouteLeg: Model {

    var distanceInMeters: NSNumber!
    var duration: NSNumber!
    var steps = [RouteLegStep]()

    var currentStepIndex: Int = 0

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "Length": "distanceInMeters",
            "TravelTime": "duration"
            ]
        )
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "Maneuver", toKeyPath: "steps", withMapping: RouteLegStep.mapping()))
        return mapping
    }

    var distance: CLLocationDistance {
        return distanceInMeters.doubleValue
    }

    var distanceInMiles: Double {
        return distance * 0.000621371
    }

    var distanceInFeet: CLLocationDistance {
        return distanceInMiles * 5820.0
    }

    var distancePerStep: CLLocationDistance {
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

    var etaMinutes: Int {
        let minutes = duration.doubleValue / 60.0 //duration.doubleValue / Double(steps.count - 1) / 60.0
        return Int(round(minutes))
    }

    var isFinished: Bool {
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
