//
//  Invitation.swift
//  provide
//
//  Created by Kyle Thomas on 3/5/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

class Invitation: Model {

    var id = 0
    var user: User!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id",
        ])
        mapping?.addRelationshipMapping(withSourceKeyPath: "user", mapping: User.mapping())
        return mapping!
    }
}
