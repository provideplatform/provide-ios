//
//  UserToken.swift
//  provide
//
//  Created by Kyle Thomas on 3/5/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

@objcMembers
class UserToken: Model {

    private(set) var user: User!
    private(set) var token: Token!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addRelationshipMapping(withSourceKeyPath: "user", mapping: User.mapping())
        mapping?.addRelationshipMapping(withSourceKeyPath: "token", mapping: Token.mapping())
        return mapping!
    }
}
