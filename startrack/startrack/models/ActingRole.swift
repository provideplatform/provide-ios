//
//  ActingRole.swift
//  startrack
//
//  Created by Kyle Thomas on 9/12/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class ActingRole: Model {

    var id = 0
    var name: String!
    var productionName: String!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromArray([
            "id",
            "name",
            ]
        )
        mapping.addAttributeMappingsFromDictionary([
            "production_name": "productionName",
        ])
        return mapping
    }
}
