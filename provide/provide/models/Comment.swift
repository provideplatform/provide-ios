//
//  Comment.swift
//  provide
//
//  Created by Kyle Thomas on 7/20/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Comment: Model {

    var id = 0
    var body: String!
    var createdAt: String!
    var user: User!
    var attachments: [Attachment]!

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
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", withMapping: Attachment.mapping()))
        return mapping
    }

    var images: [Attachment] {
        var images = [Attachment]()
        if let attachments = attachments {
            if attachments.count > 0 {
                for attachment in attachments {
                    if let mimeType = attachment.mimeType {
                        if mimeType == "image/png" || mimeType == "image/jpg" {
                            images.append(attachment)
                        }
                    }
                }
            }
        }
        return images
    }
}
