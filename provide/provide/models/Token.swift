//
//  Token.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Token: Model {

    var id = 0
    var uuid: String!
    var token: String!
    var user: User!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromArray([
            "id",
            "uuid",
            "token",
            ]
        )
        mapping.addRelationshipMappingWithSourceKeyPath("user", mapping: User.mapping())
        return mapping
    }

    var userId: NSNumber {
        return user.id
    }

    var authorizationHeaderString: String {
        return "Basic " + "\(token):\(uuid)".base64EncodedString
    }
}
