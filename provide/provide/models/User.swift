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
        mapping.addAttributeMappingsFromArray([
            "id",
            "name",
            "email",
            "profile_image_url",
            ]
        )
        mapping.addRelationshipMappingWithSourceKeyPath("contact", mapping: Contact.mapping())
        return mapping
    }
}


// MARK: - Functions

func currentUser() -> User {
    var user: User!
    while user == nil {
        if let token = KeyChainService.sharedService().token {
            user = token.user
        }
    }
    return user
}
