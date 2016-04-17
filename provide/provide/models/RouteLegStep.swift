//
//  RouteLegStep.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class RouteLegStep: Model {

    let maneuverIcons = [
        "leftUTurn":            "uturn-left",
        "leftTurn":             "turn-left",
        "slightLeftTurn":       "turn-slight-left",
        "sharpLeftTurn":        "turn-sharp-left",
        "leftMerge":            "merge",
        "leftExit":             "exit-left",
        "leftLoop":             "",
        "leftFork":             "fork-left",
        "leftRamp":             "ramp-left",
        "leftRoundaboutExit1":  "roundabout-left",
        "rightUTurn":           "uturn-right",
        "rightTurn":            "turn-right",
        "slightRightTurn":      "turn-slight-right",
        "sharpRightTurn":       "turn-sharp-right",
        "rightMerge":           "merge",
        "rightExit":            "exit-right",
        "rightFork":            "fork-right",
        "rightLoop":            "",
        "rightRamp":            "ramp-right",
        "rightRoundaboutExit1": "roundabout-right",
        "arrive":               "",
        "arriveLeft":           "",
        "arriveRight":          "",
        "arriveAirport":        "",
        "depart":               "",
        "departAirport":        "",
        "continue":             "straight",
        "middleFork":           "straight",
        "nameChange":           "",
        "trafficCircle":        "",
        "ferry":                "",
    ]

    var identifier: String!
    var position: [String: AnyObject]!
    var instruction: String!
    var distanceInMeters: NSNumber!
    var duration: NSNumber!
    // var placeEquipment = [AnyObject]() // unused
    var shape: [String]!
    var direction: String!
    var maneuver: String!
    var time: String!
    var baseTime: NSNumber!
    var nextManeuver: String!
    var toLink: String!

    var currentShapeIndex: Int = 0

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "Position": "position",
            "Instruction": "instruction",
            "PlaceEquipment": "placeEquipment",
            "Length": "distanceInMeters",
            "TravelTime": "duration",
            "Shape": "shape",
            "Time": "time",
            "Direction": "direction",
            "Action": "maneuver",
            "BaseTime": "baseTime",
            "NextManeuver": "nextManeuver",
            "ToLink": "toLink",
            "id": "identifier"
            ]
        )
        return mapping
    }

    var maneuverIcon: UIImage! {
        if let iconName = maneuverIcons[maneuver] {
            return UIImage(iconName)
        }
        return nil
    }

    var distance: CLLocationDistance! {
        if let distanceInMeters = distanceInMeters {
            return distanceInMeters.doubleValue
        }
        return 0.0
    }

    var distanceInMiles: Double {
        return distance * 0.000621371
    }

    var distanceInFeet: Double! {
        return distanceInMiles * 5820.0
    }

    var remainingDistanceString: String! {
        if let shape = shape where shape.count > 0 {
            let distanceInMiles = self.distanceInMiles - (self.distanceInMiles * (Double(currentShapeIndex) / Double(shape.count)))
            if distanceInMiles > 0.1 {
                return String(format: "%.1f", distanceInMiles) + " mi"
            } else {
                let distanceInFeet = self.distanceInFeet - (self.distanceInFeet * (Double(currentShapeIndex) / Double(shape.count)))
                return String(format: "%.0f", ceil(distanceInFeet)) + " ft"
            }
        }
        return "--"
    }

    var distanceString: String {
        if distanceInMiles > 0.1 {
            return String(format: "%.1f", distanceInMiles) + " mi"
        } else {
            return String(format: "%.0f", ceil(distanceInFeet)) + " ft"
        }
    }

    var isFinished: Bool {
        return currentShapeIndex == shape.count - 1
    }

    var regionIdentifier: String {
        return identifier
    }

    var regionMonitoringRadius: CLLocationDistance {
        return 25.0
    }

    var regionOverlay: MKCircle! {
        if let endCoordinate = endCoordinate {
            return MKCircle(centerCoordinate: endCoordinate, radius: regionMonitoringRadius)
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
        for shapeString in shape {
            let shapeCoords = shapeString.splitAtString(",")
            let latitude = Double(shapeCoords.0)
            let longitude = Double(shapeCoords.1)
            if latitude != nil && longitude != nil {
                coords.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            }
        }
        return coords
    }

    var startCoordinate: CLLocationCoordinate2D! {
        if let shape = shape {
            if shape.count == 0 {
                return nil
            }

            if let startLocation = shape.first {
                let startCoords = startLocation.splitAtString(",")
                let latitude = (startCoords.0 as NSString).doubleValue
                let longitude = (startCoords.1 as NSString).doubleValue
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
        }

        return nil
    }

    var endCoordinate: CLLocationCoordinate2D! {
        if let shape = shape {
            if shape.count == 0 {
                return nil
            }

            if let endLocation = shape.last {
                let endCoords = endLocation.splitAtString(",")
                let latitude = (endCoords.0 as NSString).doubleValue
                let longitude = (endCoords.1 as NSString).doubleValue
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
        }

        return nil
    }
}
