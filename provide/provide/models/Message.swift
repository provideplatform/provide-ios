//
//  Message.swift
//  provide
//
//  Created by Jawwad Ahmad on 5/25/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit
import RestKit
import JSQMessagesViewController

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

        mapping.addAttributeMappingsFromArray([
            "body",
            "created_at",
            "id",
            "recipient_id",
            "recipient_name",
            "sender_name",
            "sender_profile_image_url",
            ]
        )

        // sender_id does not follow camel case convention
        mapping.addAttributeMappingsFromDictionary([
            "sender_id": "senderID",
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
