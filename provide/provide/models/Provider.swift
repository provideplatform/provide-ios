//
//  Provider.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Provider: Model {

    var id: NSNumber!
    var userId: NSNumber!
    var name: String!
    var contact: Contact!
    var services: NSSet!

    class func mapping() -> RKObjectMapping {
        var mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "user_id": "userId",
            "name": "name",
            "services": "services"
        ])
        mapping.addRelationshipMappingWithSourceKeyPath("contact", mapping: Contact.mapping())
        return mapping
    }

    var firstName: String! {
        get {
            var firstName: String!
            if let name = self.name {
                firstName = name.splitAtString(" ").0
            }
            return firstName
        }
    }

    var lastName: String! {
        get {
            var lastName: String!
            if let name = self.name {
                lastName = name.splitAtString(" ").1
            }
            return lastName
        }
    }

}
