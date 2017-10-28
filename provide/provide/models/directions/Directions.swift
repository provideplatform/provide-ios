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

    var routes = [Route]()
    var minutes: Int = 0
    var selectedRouteIndex: Int!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "minutes",
        ])
        mapping?.addRelationshipMapping(withSourceKeyPath: "routes", mapping: Route.mapping())
        return mapping!
    }

    var selectedRoute: Route? {
        guard routes.count > 0 else { return nil }

        if selectedRouteIndex == nil {
            selectedRouteIndex = 0
        }

        return routes[selectedRouteIndex]
    }
}
