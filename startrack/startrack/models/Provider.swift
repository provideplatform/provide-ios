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
    var contact: Contact!
    var profileImageUrlString: String!
    var services: NSSet!

    var name: String! {
        if let name = contact?.name {
            return  name
        }
        return nil
    }

    var age: Int {
        return 29 // FIXME
    }

    var profileImageUrl: NSURL? {
        guard let profileImageUrlString = profileImageUrlString else { return nil }
        return NSURL(string: profileImageUrlString)
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "user_id": "userId",
            "name": "name",
            "services": "services",
            "profile_image_url": "profileImageUrlString"
            ])
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
