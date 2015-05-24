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
    var steps: NSArray!

    var currentStepIndex: Int = 0

    override class func mapping() -> RKObjectMapping {
        var mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "Length": "distanceInMeters",
            "TravelTime": "duration"
        ])
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "Maneuver", toKeyPath: "steps", withMapping: RouteLegStep.mapping()))
        return mapping
    }

    var distance: CLLocationDistance! {
        get {
            return distanceInMeters.doubleValue
        }
    }

    var distanceInMiles: Double {
        get {
            return distance * 0.000621371
        }
    }

    var distanceInFeet: CLLocationDistance! {
        get {
            return distanceInMiles * 5820.0
        }
    }

    var distancePerStep: CLLocationDistance! {
        get {
            return distance / Double(steps.count)
        }
    }

    var distanceString: String! {
        get {
            if distanceInMiles > 0.1 {
                return String(format: "%.1f", distanceInMiles) + " mi"
            } else {
                return String(format: "%.0f", ceil(distanceInFeet)) + " ft"
            }
        }
    }

    var durationString: String! {
        get {
            return "\(etaMinutes) min"
        }
    }

    var etaMinutes: Int! {
        get {
            var minutes = duration.doubleValue / 60.0 //duration.doubleValue / Double(steps.count - 1) / 60.0
            return Int(round(minutes))
        }
    }

    var isFinished: Bool {
        get {
            if steps == nil {
                return false
            }
            
            return currentStepIndex == steps.count - 1
        }
    }

    var currentStep: RouteLegStep! {
        get {
            var step: RouteLegStep!

            if let steps = steps {
                if currentStepIndex <= steps.count - 1 {
                    step = steps[currentStepIndex] as! RouteLegStep
                }
            }

            return step
        }
    }

    var nextStep: RouteLegStep! {
        get {
            var step: RouteLegStep!

            if let steps = steps {
                let nextStepIndex = currentStepIndex + 1
                if nextStepIndex <= steps.count - 1 {
                    step = steps[nextStepIndex] as! RouteLegStep
                }
            }

            return step
        }
    }

}
