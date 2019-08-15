//
//  Maneuver.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

@objcMembers
class Maneuver: Model {

    let maneuverIcons = [
        "leftUTurn": "uturn-left",
        "leftTurn": "turn-left",
        "slightLeftTurn": "turn-slight-left",
        "sharpLeftTurn": "turn-sharp-left",
        "leftMerge": "merge",
        "leftExit": "exit-left",
        "leftLoop": "",
        "leftFork": "fork-left",
        "leftRamp": "ramp-left",
        "leftRoundaboutExit1": "roundabout-left",
        "rightUTurn": "uturn-right",
        "rightTurn": "turn-right",
        "slightRightTurn": "turn-slight-right",
        "sharpRightTurn": "turn-sharp-right",
        "rightMerge": "merge",
        "rightExit": "exit-right",
        "rightFork": "fork-right",
        "rightLoop": "",
        "rightRamp": "ramp-right",
        "rightRoundaboutExit1": "roundabout-right",
        "arrive": "",
        "arriveLeft": "",
        "arriveRight": "",
        "arriveAirport": "",
        "depart": "",
        "departAirport": "",
        "continue": "straight",
        "middleFork": "straight",
        "nameChange": "",
        "trafficCircle": "",
        "ferry": "",
    ]

    var action: String!
    var coordinates: [String: Double]!
    var direction: String!
    var distance: Double = 0
    var duration: Double = 0
    var id: String!
    var instruction: String!
    var miles: Double = 0
    var minutes: Double = 0
    var nextManeuver: String!
    var shape: [String]!
    var time: String!
    var toLink: String!

    var currentShapeIndex: Int = 0

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "action",
            "coordinates",
            "direction",
            "distance",
            "duration",
            "id",
            "instruction",
            "miles",
            "minutes",
            "next_maneuver",
            "shape",
            "time",
            "to_link",
        ])
        return mapping!
    }

    var maneuverIcon: UIImage? {
        return maneuverIcons[action].flatMap { UIImage(named: $0) }
    }

    private var feet: Double {
        return miles * 5820.0
    }

    var remainingDistanceString: String {
        if let shape = shape, shape.count > 0 {
            let miles = self.miles - (self.miles * (Double(currentShapeIndex) / Double(shape.count)))
            if miles > 0.1 {
                return String(format: "%.1f", miles) + " mi"
            } else {
                let distanceInFeet = self.feet - (self.feet * (Double(currentShapeIndex) / Double(shape.count)))
                return String(format: "%.0f", ceil(distanceInFeet)) + " ft"
            }
        }
        return "--"
    }

    private var distanceString: String {
        if miles > 0.1 {
            return String(format: "%.1f", miles) + " mi"
        } else {
            return String(format: "%.0f", ceil(feet)) + " ft"
        }
    }

    var isFinished: Bool {
        return currentShapeIndex == shape.count - 1
    }

    private var regionIdentifier: String {
        return id
    }

    private var regionMonitoringRadius: CLLocationDistance {
        return 25.0
    }

    private var regionOverlay: MKCircle? {
        if let endCoordinate = endCoordinate {
            return MKCircle(center: endCoordinate, radius: regionMonitoringRadius)
        }
        return nil
    }

    var currentShapeCoordinate: CLLocationCoordinate2D? {
        let currentShapeIndex = self.currentShapeIndex
        if currentShapeIndex < shapeCoordinates.count - 1 {
            return shapeCoordinates[currentShapeIndex]
        }
        return nil
    }

    var shapeCoordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D]()
        for str in shape {
            let shapeCoords = str.components(separatedBy: ",")

            if let latitude = Double(shapeCoords.first!), let longitude = Double(shapeCoords.last!) {
                coords.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            }
        }
        return coords
    }

    var startCoordinate: CLLocationCoordinate2D? {
        if let shape = shape {
            if shape.count == 0 {
                return nil
            }

            if let startLocation = shape.first {
                let startCoords = startLocation.components(separatedBy: ",")
                let latitude = (startCoords.first! as NSString).doubleValue
                let longitude = (startCoords.last! as NSString).doubleValue
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
        }

        return nil
    }

    var endCoordinate: CLLocationCoordinate2D? {
        if let shape = shape {
            if shape.count == 0 {
                return nil
            }

            if let endLocation = shape.last {
                let endCoords = endLocation.components(separatedBy: ",")
                let latitude = (endCoords.first! as NSString).doubleValue
                let longitude = (endCoords.last! as NSString).doubleValue
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
        }

        return nil
    }
}
