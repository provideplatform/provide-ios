//
//  Company.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Company: Model {

    var id: NSNumber!
    var name: String!
    var contact: Contact!

    override class func mapping() -> RKObjectMapping {
        var mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "name": "name"
        ])
        mapping.addRelationshipMappingWithSourceKeyPath("contact", mapping: Contact.mapping())
        return mapping
    }

}
