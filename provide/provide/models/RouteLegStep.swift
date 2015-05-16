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
    let maneuverIcons = NSDictionary(dictionary: [
        "leftUTurn": UIImage(named: "uturn-left")!,
        "leftTurn": UIImage(named: "left")!,
        "slightLeftTurn": UIImage(named: "left")!,
        "sharpLeftTurn": UIImage(named: "left")!,
        "leftMerge": UIImage(named: "left")!,
        "leftExit": UIImage(named: "exit-left")!,
        "leftLoop": UIImage(named: "left")!,
        "leftFork": UIImage(named: "left")!,
        "leftRamp": UIImage(named: "left")!,
        "leftRoundaboutExit1": UIImage(named: "roundabout-left")!,
        "rightUTurn": UIImage(named: "uturn-right")!,
        "rightTurn": UIImage(named: "right")!,
        "slightRightTurn": UIImage(named: "right")!,
        "sharpRightTurn": UIImage(named: "right")!,
        "rightMerge": UIImage(named: "right")!,
        "rightExit": UIImage(named: "exit-right")!,
        "rightFork": UIImage(named: "right")!,
        "rightLoop": UIImage(named: "right")!,
        "rightRamp": UIImage(named: "right")!,
        "rightRoundaboutExit1": UIImage(named: "roundabout-right")!,
        "arrive": UIImage(named: "maneuver-icon-sprites")!,
        "arriveLeft": UIImage(named: "maneuver-icon-sprites")!,
        "arriveRight": UIImage(named: "maneuver-icon-sprites")!,
        "arriveAirport": UIImage(named: "maneuver-icon-sprites")!,
        "depart": UIImage(named: "maneuver-icon-sprites")!,
        "departAirport": UIImage(named: "maneuver-icon-sprites")!,
        "continue": UIImage(named: "straight")!,
        "middleFork": UIImage(named: "straight")!,
        "nameChange": UIImage(named: "maneuver-icon-sprites")!,
        "trafficCircle": UIImage(named: "maneuver-icon-sprites")!,
        "ferry": UIImage(named: "maneuver-icon-sprites")!
    ])

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

    class func mapping() -> RKObjectMapping {
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

    var maneuverIcon: UIImage! {
        get {
            return maneuverIcons[maneuver] as! UIImage!
        }
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

    var distanceInFeet: Double! {
        get {
            return distanceInMiles * 5820.0
        }
    }

    var remainingDistanceString: String! {
        get {
            var distanceInMiles = self.distanceInMiles - (self.distanceInMiles * (Double(currentShapeIndex) / Double(shape.count)))
            if distanceInMiles > 0.1 {
                return String(format: "%.1f", distanceInMiles) + " mi"
            } else {
                var distanceInFeet = self.distanceInFeet - (self.distanceInFeet * (Double(currentShapeIndex) / Double(shape.count)))
                return String(format: "%.0f", ceil(distanceInFeet)) + " ft"
            }
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

    var isFinished: Bool {
        get {
            if shape == nil {
                return false
            }

            return currentShapeIndex == shape.count - 1
        }
    }

    var regionIdentifier: String! {
        get {
            return identifier
        }
    }

    var regionMonitoringRadius: CLLocationDistance {
        get {
            return 25.0
        }
    }

    var regionOverlay: MKCircle! {
        get {
            if let endCoordinate = self.endCoordinate {
                return MKCircle(centerCoordinate: endCoordinate, radius: regionMonitoringRadius)
            }
            return nil
        }
    }

    var currentShapeCoordinate: CLLocationCoordinate2D {
        get {
            return shapeCoordinates[currentShapeIndex]
        }
    }

    var shapeCoordinates: [CLLocationCoordinate2D] {
        get {
            var coords = [CLLocationCoordinate2D]()
            if let shape = self.shape {
                for shapeString in shape {
                    let shapeCoords = (shapeString as! String).splitAtString(",")
                    let latitude = (shapeCoords.0 as NSString).doubleValue
                    let longitude = (shapeCoords.1 as NSString).doubleValue
                    coords.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                }
            }

            return coords
        }
    }

    var startCoordinate: CLLocationCoordinate2D! {
        get {
            if let startLocation = (self.shape as Array).first as? String {
                let startCoords = startLocation.splitAtString(",")
                let latitude = (startCoords.0 as NSString).doubleValue
                let longitude = (startCoords.1 as NSString).doubleValue
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }

            return nil
        }
    }

    var endCoordinate: CLLocationCoordinate2D! {
        get {
            if let endLocation = (self.shape as Array).last as? String {
                let endCoords = endLocation.splitAtString(",")
                let latitude = (endCoords.0 as NSString).doubleValue
                let longitude = (endCoords.1 as NSString).doubleValue
                return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }

            return nil
        }
    }

}
