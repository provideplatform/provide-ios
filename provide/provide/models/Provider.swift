//
//  Provider.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Provider: Model {

    var id = 0
    var userId = 0
    var name: String!
    var contact: Contact!
    var services: NSSet!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromArray([
            "id",
            "user_id",
            "name",
            "services",
            ]
        )
        mapping.addRelationshipMappingWithSourceKeyPath("contact", mapping: Contact.mapping())
        return mapping
    }

    var firstName: String? {
        if let name = name {
            return name.splitAtString(" ").0
        } else {
            return nil
        }
    }

    var lastName: String? {
        if let name = name {
            return name.splitAtString(" ").1
        } else {
            return nil
        }
    }
}
