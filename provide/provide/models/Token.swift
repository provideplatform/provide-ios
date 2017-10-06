//
//  Token.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

class Token: Model {

    var id = 0
    var uuid: String!
    var token: String!
    var user: User!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id",
            "uuid",
            "token",
        ])
        mapping?.addRelationshipMapping(withSourceKeyPath: "user", mapping: User.mapping())
        return mapping!
    }

    var userId: NSNumber {
        return NSNumber(value: user.id)
    }

    var authorizationHeaderString: String! {
        if let token = token, let uuid = uuid {
            return "Basic " + "\(token):\(uuid)".base64EncodedString
        }
        return nil
    }
}
