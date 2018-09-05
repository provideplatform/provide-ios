//
//  Comment.swift
//  provide
//
//  Created by Kyle Thomas on 7/20/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Comment: Model {

    var id: NSNumber!
    var body: String!
    var createdAt: String!
    var user: User!

    var createdAtDate: NSDate! {
        if let createdAt = createdAt {
            return NSDate.from(createdAt)
        }
        return nil
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id": "id",
            "body": "body",
            "created_at": "createdAt"
            ])
        mapping?.addRelationshipMapping(withSourceKeyPath: "user", mapping: User.mapping())
        return mapping!
    }
}
