//
//  RouteLegStep.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class RouteLegStep: Model {

    let maneuverIconSprites = UIImage(named: "maneuver-icon-sprites")
    let maneuverIconHeight = 18.0
    let maneuverIcons = [
        "leftUTurn":            "uturn-left",
        "leftTurn":             "left",
        "slightLeftTurn":       "left",
        "sharpLeftTurn":        "left",
        "leftMerge":            "left",
        "leftExit":             "exit-left",
        "leftLoop":             "left",
        "leftFork":             "left",
        "leftRamp":             "left",
        "leftRoundaboutExit1":  "roundabout-left",
        "rightUTurn":           "uturn-right",
        "rightTurn":            "right",
        "slightRightTurn":      "right",
        "sharpRightTurn":       "right",
        "rightMerge":           "right",
        "rightExit":            "exit-right",
        "rightFork":            "right",
        "rightLoop":            "right",
        "rightRamp":            "right",
        "rightRoundaboutExit1": "roundabout-right",
        "arrive":               "maneuver-icon-sprites",
        "arriveLeft":           "maneuver-icon-sprites",
        "arriveRight":          "maneuver-icon-sprites",
        "arriveAirport":        "maneuver-icon-sprites",
        "depart":               "maneuver-icon-sprites",
        "departAirport":        "maneuver-icon-sprites",
        "continue":             "straight",
        "middleFork":           "straight",
        "nameChange":           "maneuver-icon-sprites",
        "trafficCircle":        "maneuver-icon-sprites",
        "ferry":                "maneuver-icon-sprites",
    ]

    var identifier: String!
    var position: NSDictionary!
    var instruction: String!
    var distanceInMeters: NSNumber!
    var duration: NSNumber!
    var placeEquipment: NSArray!
    var shape: NSArray!
    var direction: String!
    var maneuver: String!
    var time: String!
    var baseTime: NSNumber!
    var nextManeuver: String!
    var toLink: String!

    var currentShapeIndex: Int = 0

    override class func mapping() -> RKObjectMapping {
        var mapping = RKObjectMapping(forClass: self)
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
            ])
        return mapping
    }

    var maneuverIcon: UIImage {
        return UIImage(named: maneuverIcons[maneuver]!)!
    }

    var distance: CLLocationDistance! {
        return distanceInMeters.doubleValue
    }

    var distanceInMiles: Double {
        return distance * 0.000621371
    }

    var distanceInFeet: Double! {
        return distanceInMiles * 5820.0
    }

    var remainingDistanceString: String! {
        var distanceInMiles = self.distanceInMiles - (self.distanceInMiles * (Double(currentShapeIndex) / Double(shape.count)))
        if distanceInMiles > 0.1 {
            return String(format: "%.1f", distanceInMiles) + " mi"
        } else {
            var distanceInFeet = self.distanceInFeet - (self.distanceInFeet * (Double(currentShapeIndex) / Double(shape.count)))
            return String(format: "%.0f", ceil(distanceInFeet)) + " ft"
        }
    }

    var distanceString: String! {
        if distanceInMiles > 0.1 {
            return String(format: "%.1f", distanceInMiles) + " mi"
        } else {
            return String(format: "%.0f", ceil(distanceInFeet)) + " ft"
        }
    }

    var isFinished: Bool {
        if shape == nil {
            return false
        }

        return currentShapeIndex == shape.count - 1
    }

    var regionIdentifier: String! {
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

    var currentShapeCoordinate: CLLocationCoordinate2D {
        return shapeCoordinates[currentShapeIndex]
    }

    var shapeCoordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D]()
        if let shape = shape {
            for shapeString in shape {
                let shapeCoords = (shapeString as! String).splitAtString(",")
                let latitude = (shapeCoords.0 as NSString).doubleValue
                let longitude = (shapeCoords.1 as NSString).doubleValue
                coords.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            }
        }

        return coords
    }

    var startCoordinate: CLLocationCoordinate2D! {
        if let startLocation = (shape as Array).first as? String {
            let startCoords = startLocation.splitAtString(",")
            let latitude = (startCoords.0 as NSString).doubleValue
            let longitude = (startCoords.1 as NSString).doubleValue
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        return nil
    }

    var endCoordinate: CLLocationCoordinate2D! {
        if let endLocation = (shape as Array).last as? String {
            let endCoords = endLocation.splitAtString(",")
            let latitude = (endCoords.0 as NSString).doubleValue
            let longitude = (endCoords.1 as NSString).doubleValue
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        return nil
    }

}
