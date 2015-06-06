//
//  Message.swift
//  provide
//
//  Created by Jawwad Ahmad on 5/25/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class Message: Model {
    var body = ""
    var createdAt: NSDate!
    var id = 0
    var recipientId = 0
    var recipientName: String!
    var senderID = 0
    var senderName: String!
    var senderProfileImageUrl: NSURL!

    convenience init(text: String, recipientId: Int) {
        self.init()

        self.body = text
        self.recipientId = recipientId
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "body": "body",
            "created_at": "createdAt",
            "id": "id",
            "recipient_id": "recipientId",
            "recipient_name": "recipientName",
            "sender_id": "senderID",
            "sender_name": "senderName",
            "sender_profile_image_url": "senderProfileImageUrl",
            ]
        )
        return mapping
    }
}

extension Message: JSQMessageData {
    func text() -> String {
        return body
    }

    func senderId() -> String {
        return senderID.description
    }

    func senderDisplayName() -> String {
        return senderName
    }

    func date() -> NSDate {
        return createdAt
    }

    func isMediaMessage() -> Bool {
        return false
    }

    func messageHash() -> UInt {
        let hash = senderId().hash ^ date().hash ^ text().hash
        return UInt(abs(hash))
    }
}
