//
//  User.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class User: Model {

    var id = 0
    var name: String!
    var email: String!
    var profileImageUrl: String?
    var contact: Contact!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "name": "name",
            "email": "email",
            "profile_image_url": "profileImageUrl"
        ])
        mapping.addRelationshipMappingWithSourceKeyPath("contact", mapping: Contact.mapping())
        return mapping
    }
}


// MARK: - Functions

func currentUser() -> User {
    return KeyChainService.sharedService().token!.user
}
