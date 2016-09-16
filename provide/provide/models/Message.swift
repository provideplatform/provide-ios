//
//  Message.swift
//  provide
//
//  Created by Jawwad Ahmad on 5/25/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import RestKit
import JSQMessagesViewController

class Message: Model {
    var body = ""
    var createdAt: Date!
    var id = 0
    var recipientId = 0
    var recipientName: String!
    var senderID = 0
    var senderName: String!
    var senderProfileImageUrl: URL!

    convenience init(text: String, recipientId: Int) {
        self.init()

        self.body = text
        self.recipientId = recipientId
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)

        mapping?.addAttributeMappings(from: [
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
        mapping?.addAttributeMappings(from: [
            "sender_id": "senderID",
            ]
        )
        return mapping!
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

    func date() -> Date {
        return createdAt
    }

    func isMediaMessage() -> Bool {
        return false
    }

    func messageHash() -> UInt {
        let hash = senderId().hash ^ (date() as NSDate).hash ^ text().hash
        return UInt(abs(hash))
    }
}
