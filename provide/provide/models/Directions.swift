//
//  Directions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

class Directions: Model {

    var routes = [Route]()
    var minutes: NSNumber!
    var selectedRouteIndex: Int!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromArray([
            "minutes",
            ]
        )
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "Route", toKeyPath: "routes", withMapping: Route.mapping()))
        return mapping
    }

    var selectedRoute: Route! {
        if routes.count > 0 {
            if selectedRouteIndex == nil {
                selectedRouteIndex = 0
            }

            return routes[selectedRouteIndex]
        }
        return nil
    }
}
