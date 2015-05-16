//
//  Directions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Directions: Model {

    var routes: NSArray!
    var minutes: NSNumber!
    var selectedRouteIndex: Int!

    class func mapping() -> RKObjectMapping {
        var mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "minutes": "minutes"
        ])
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "Route", toKeyPath: "routes", withMapping: Route.mapping()))
        return mapping
    }

    var selectedRoute: Route! {
        get {
            if routes.count > 0 {
                if selectedRouteIndex == nil {
                    selectedRouteIndex = 0
                }
                
                return routes[selectedRouteIndex] as! Route
            }
            return nil
        }
    }

}
