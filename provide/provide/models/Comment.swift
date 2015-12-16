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
            return NSDate.fromString(createdAt)
        }
        return nil
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "body": "body",
            "created_at": "createdAt"
            ])
        mapping.addRelationshipMappingWithSourceKeyPath("user", mapping: User.mapping())
        return mapping
    }
}
