//
//  Customer.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Customer: Model {

    var id = 0
    var name: String!
    var displayName: String!
    var profileImageUrl: String!
    var contact: Contact!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromArray([
            "id",
            "name",
            "display_name",
            "profile_image_url",
            ]
        )
        mapping.addRelationshipMappingWithSourceKeyPath("contact", mapping: Contact.mapping())
        return mapping
    }
}
