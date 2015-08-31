//
//  WorkOrderProvider.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class WorkOrderProvider: Model {

    var id = 0
    var providerRating: NSNumber!
    var provider: Provider!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromArray([
            "id",
            "provider_rating",
            ]
        )
        mapping.addRelationshipMappingWithSourceKeyPath("provider", mapping: Provider.mapping())
        return mapping
    }
}