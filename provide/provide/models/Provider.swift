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
    var profileImageUrlString: String!
    var services: NSSet!

    var profileImageUrl: NSURL! {
        if let profileImageUrlString = profileImageUrlString {
            return NSURL(string: profileImageUrlString)
        }
        return nil
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
