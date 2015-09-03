//
//  ProviderOriginAssignment.swift
//  provide
//
//  Created by Kyle Thomas on 6/28/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class ProviderOriginAssignment: Model {

    var id: NSNumber!
    var origin: Origin!
    var provider: Provider!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            ])
        mapping.addRelationshipMappingWithSourceKeyPath("provider", mapping: Provider.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("origin", mapping: Origin.mapping())
        return mapping
    }
}
