//
//  Token.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Token: Model {

    var id: NSNumber!
    var uuid: String!
    var token: String!
    var user: User!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "uuid": "uuid",
            "token": "token"
            ])
        mapping.addRelationshipMappingWithSourceKeyPath("user", mapping: User.mapping())
        return mapping
    }

    var userId: NSNumber! {
        return user.id
    }

    var authorizationHeaderString: String {
        return "Basic " + "\(token):\(uuid)".base64EncodedString
    }

}
