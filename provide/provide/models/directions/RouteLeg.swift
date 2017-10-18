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

    var distance: Double = 0
    var duration: Double = 0
    var miles: Double = 0
    var minutes: Double = 0
    var maneuvers = [Maneuver]()

    var currentManeuverIndex: Int = 0

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "distance",
            "duration",
            "miles",
            "minutes",
        ])
        mapping?.addRelationshipMapping(withSourceKeyPath: "maneuvers", mapping: Maneuver.mapping())
        return mapping!
    }

    private var feet: Double {
        return miles * 5820.0
    }

    var distanceString: String {
        if miles > 0.1 {
            return String(format: "%.1f", miles) + " mi"
        } else {
            return String(format: "%.0f", ceil(feet)) + " ft"
        }
    }

    var durationString: String {
        return "\(minutes) min"
    }

    private var isFinished: Bool {
        return currentManeuverIndex == maneuvers.count - 1
    }

    var currentManeuver: Maneuver! {
        var maneuver: Maneuver!
        if currentManeuverIndex <= maneuvers.count - 1 {
            maneuver = maneuvers[currentManeuverIndex]
        }
        return maneuver
    }

    var nextManeuver: Maneuver! {
        var maneuver: Maneuver!
        let nextManeuverIndex = currentManeuverIndex + 1
        if nextManeuverIndex <= maneuvers.count - 1 {
            maneuver = maneuvers[nextManeuverIndex]
        }
        return maneuver
    }
}
