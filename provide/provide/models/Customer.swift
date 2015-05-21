//
//  Customer.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Customer: Model {

    var id: NSNumber!
    var name: String!
    var displayName: String!
    var profileImageUrl: String!
    var contact: Contact!

    override class func mapping() -> RKObjectMapping {
        var mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "name": "name",
            "display_name": "displayName",
            "profile_image_url": "profileImageUrl"
        ])
        mapping.addRelationshipMappingWithSourceKeyPath("contact", mapping: Contact.mapping())
        return mapping
    }

}
