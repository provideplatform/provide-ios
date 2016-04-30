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
    var commentableType: String!
    var commentableId = 0
    var user: User!
    var attachments: [Attachment]!

    var createdAtDate: NSDate! {
        if let createdAt = createdAt {
            return NSDate.fromString(createdAt)
        }
        return nil
    }

    var isWorkOrderComment: Bool {
        if let commentableType = commentableType {
            return commentableType == "work_order"
        }
        return false
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "body": "body",
            "created_at": "createdAt",
            "commentable_type": "commentableType",
            "commentable_id": "commentableId",
            ])
        mapping.addRelationshipMappingWithSourceKeyPath("user", mapping: User.mapping())
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", withMapping: Attachment.mappingWithRepresentations()))
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

    func mergeAttachment(attachment: Attachment) {
        if attachments == nil {
            attachments = [Attachment]()
        }

        var replaced = false
        var index = 0
        for a in attachments {
            if a.id == attachment.id {
                self.attachments[index] = attachment
                replaced = true
                break
            }
            index += 1
        }

        if !replaced {
            attachments.append(attachment)
        }
    }
}
