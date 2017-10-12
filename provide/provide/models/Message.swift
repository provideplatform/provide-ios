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

private let elapsedTimeStringFormatter: DateComponentsFormatter = {
    $0.allowedUnits = [.year, .month, .weekOfMonth, .day, .hour, .minute, .second]
    $0.unitsStyle = .full
    $0.maximumUnitCount = 1
    return $0
}(DateComponentsFormatter())

private let elapsedTimeStringAbbreviatedFormatter: DateComponentsFormatter = {
    $0.allowedUnits = [.year, .month, .weekOfMonth, .day, .hour, .minute, .second]
    $0.unitsStyle = .abbreviated
    $0.maximumUnitCount = 1
    return $0
}(DateComponentsFormatter())

@objcMembers
class Message: Model {

    private var body = ""
    var mediaUrl: String!
    private var createdAt: Date!
    private var id = 0
    var recipientId = 0
    private var recipientName: String!
    var senderID = 0
    var senderName: String!
    var senderProfileImageUrl: URL!

    private var elapsedTimeString: String {
        return elapsedTimeStringFormatter.string(from: createdAt, to: Date())!.components(separatedBy: ", ").first! + " ago"
    }

    var elapsedTimeStringAbbreviated: String {
        return elapsedTimeStringAbbreviatedFormatter.string(from: createdAt, to: Date())!.components(separatedBy: ", ").first!
    }

    convenience init(text: String, recipientId: Int) {
        self.init()

        self.body = text
        self.recipientId = recipientId
    }

    convenience init(body: String, mediaUrl: String?, recipientId: Int, senderId: Int, senderName: String) {
        self.init()

        self.body = body
        self.mediaUrl = mediaUrl
        self.recipientId = recipientId
        self.senderID = senderId
        self.senderName = senderName
        createdAt = NSDate() as Date!
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)

        mapping?.addAttributeMappings(from: [
            "body",
            "media_url",
            "created_at",
            "id",
            "recipient_id",
            "recipient_name",
            "sender_name",
            "sender_profile_image_url",
        ])

        mapping?.addAttributeMappings(from: [
            "sender_id": "senderID",
        ])

        return mapping!
    }
}

extension Message: JSQMessageData, JSQMessageMediaData {

    func date() -> Date {
        return createdAt
    }

    func isMediaMessage() -> Bool {
        return false
    }

    func media() -> JSQMessageMediaData {
        return self
    }

    func messageHash() -> UInt {
        let hash = senderId().hash ^ (date() as NSDate).hash ^ text().hash
        return UInt(abs(hash))
    }

    func text() -> String {
        return body
    }

    func senderId() -> String {
        return String(senderID)
    }

    func senderDisplayName() -> String {
        return senderName
    }

    public func mediaView() -> UIView? {
        return nil
    }

    public func mediaViewDisplaySize() -> CGSize {
        return CGSize(width: 227.5, height: 128.0)
    }

    public func mediaPlaceholderView() -> UIView? {
        return mediaView()
    }

    public func mediaHash() -> UInt {
        return messageHash()
    }
}
