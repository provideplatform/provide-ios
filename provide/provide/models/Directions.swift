//
//  Directions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

@objcMembers
class Directions: Model {

    private var routes = [Route]()
    var minutes: Int = 0
    private var selectedRouteIndex: Int!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "minutes",
        ])
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "route", toKeyPath: "routes", with: Route.mapping()))
        return mapping!
    }

    var selectedRoute: Route! {
        guard routes.count > 0 else { return nil }

        if selectedRouteIndex == nil {
            selectedRouteIndex = 0
        }

        return routes[selectedRouteIndex]
    }
}
