//
//  Route.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

@objcMembers
class Route: Model {

    var legs = [RouteLeg]()
    var currentLegIndex = 0

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addRelationshipMapping(withSourceKeyPath: "legs", mapping: RouteLeg.mapping())
        return mapping!
    }

    var overviewPolyline: MKPolyline {
        var coords = [CLLocationCoordinate2D]()
        for leg in legs {
            for maneuver in leg.maneuvers {
                if let shape = maneuver.shape {
                    for shpe in shape {
                        let shapeCoords = shpe.components(separatedBy: ",")
                        let latitude = shapeCoords.count > 0 ? (shapeCoords.first! as NSString).doubleValue : 0.0
                        let longitude = shapeCoords.count > 1 ? (shapeCoords.last! as NSString).doubleValue : 0.0
                        coords.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                    }
                }
            }
        }

        return MKPolyline(coordinates: &coords, count: coords.count)
    }

    var currentLeg: RouteLeg! {
        var leg: RouteLeg!
        if legs.count > 0 {
            leg = legs[currentLegIndex]
        }
        return leg
    }
}
