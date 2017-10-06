//
//  Comment.swift
//  provide
//
//  Created by Kyle Thomas on 7/20/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

class Comment: Model {

    var id = 0
    var body: String!
    var createdAt: String!
    var commentableType: String!
    var commentableId = 0
    var previousCommentId = 0
    var user: User!
    var attachments: [Attachment]!

    var createdAtDate: Date! {
        if let createdAt = createdAt {
            return Date.fromString(createdAt)
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
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id": "id",
            "body": "body",
            "created_at": "createdAt",
            "commentable_type": "commentableType",
            "commentable_id": "commentableId",
            "previous_comment_id": "previousCommentId",
            ])
        mapping?.addRelationshipMapping(withSourceKeyPath: "user", mapping: User.mapping())
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", with: Attachment.mappingWithRepresentations()))
        return mapping!
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

    func mergeAttachment(_ attachment: Attachment) {
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

    func reload(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        ApiService.shared.fetchCommentWithId(String(id), forCommentableType: commentableType, withCommentableId: String(commentableId),
            onSuccess: { statusCode, mappingResult in
                let comment = mappingResult?.firstObject as! Comment

                self.body = comment.body

                if let attachments = comment.attachments {
                    self.attachments = attachments
                }

                onSuccess(statusCode, mappingResult)
            },
            onError: onError
        )
    }
}
