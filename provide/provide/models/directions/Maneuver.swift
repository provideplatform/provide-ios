//
//  Maneuver.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
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
    var shapes: [String]!
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
            "shapes",
            "time",
            "to_link",
        ])
        return mapping!
    }

    var maneuverIcon: UIImage! {
        if let iconName = maneuverIcons[action] {
            return UIImage(iconName)
        }
        return nil
    }

    private var feet: Double! {
        return miles * 5820.0
    }

    var remainingDistanceString: String! {
        if let shapes = shapes, shapes.count > 0 {
            let miles = self.miles - (self.miles * (Double(currentShapeIndex) / Double(shapes.count)))
            if miles > 0.1 {
                return String(format: "%.1f", miles) + " mi"
            } else {
                let distanceInFeet = self.feet - (self.feet * (Double(currentShapeIndex) / Double(shapes.count)))
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
        return currentShapeIndex == shapes.count - 1
    }

    private var regionIdentifier: String {
        return id
    }

    private var regionMonitoringRadius: CLLocationDistance {
        return 25.0
    }

    private var regionOverlay: MKCircle! {
        if let endCoordinate = endCoordinate {
            return MKCircle(center: endCoordinate, radius: regionMonitoringRadius)
        }
        return nil
    }

    var currentShapeCoordinate: CLLocationCoordinate2D! {
        let currentShapeIndex = self.currentShapeIndex
        if currentShapeIndex < shapeCoordinates.count - 1 {
            return shapeCoordinates[currentShapeIndex]
        }
        return nil
    }

    var shapeCoordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D]()
        for str in shapes {
            let shapeCoords = str.components(separatedBy: ",")

            if let latitude = Double(shapeCoords.first!), let longitude = Double(shapeCoords.last!) {
                coords.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            }
        }
        return coords
    }

    var startCoordinate: CLLocationCoordinate2D! {
        if let shapes = shapes {
            if shapes.count == 0 {
                return nil
            }

            if let startLocation = shapes.first {
                let startCoords = startLocation.components(separatedBy: ",")
                let latitude = (startCoords.first! as NSString).doubleValue
                let longitude = (startCoords.last! as NSString).doubleValue
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
        }

        return nil
    }

    var endCoordinate: CLLocationCoordinate2D! {
        if let shapes = shapes {
            if shapes.count == 0 {
                return nil
            }

            if let endLocation = shapes.last {
                let endCoords = endLocation.components(separatedBy: ",")
                let latitude = (endCoords.first! as NSString).doubleValue
                let longitude = (endCoords.last! as NSString).doubleValue
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
        }

        return nil
    }
}
