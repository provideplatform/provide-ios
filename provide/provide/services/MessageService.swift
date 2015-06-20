//
//  MessagesService.swift
//  provide
//
//  Created by Jawwad Ahmad on 6/4/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnMessagesFetched = (messages: [Message]) -> ()
typealias OnMessageCreated = Message -> Void

class MessageService {

    private var messages = [Message]()

    private init() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleNewMessageReceived:", name: "NewMessageReceivedNotification")
    }

    private static let sharedInstance = MessageService()

    class func sharedService() -> MessageService {
        return sharedInstance
    }

    func fetch(page: Int = 1, rpp: Int = 10, onMessagesFetched: OnMessagesFetched, onError: OnError) {
        let params = ["page": page, "rpp": rpp]

        ApiService.sharedService().fetchMessages(params,
            onSuccess: { statusCode, mappingResult in
                let fetchedMessages = mappingResult.array() as! [Message]
                self.messages += fetchedMessages
                onMessagesFetched(messages: fetchedMessages)
            },
            onError: onError
        )
    }

    func createMessage(text: String, recipientId: Int, onMessageCreated: OnMessageCreated, onError: OnError) {
        ApiService.sharedService().createMessage(["body": text, "recipient_id": recipientId],
            onSuccess: { statusCode, mappingResult in
                let message = mappingResult.firstObject as! Message
                self.messages.append(message)
                onMessageCreated(message)
            },
            onError: onError
        )
    }

    @objc private func handleNewMessageReceived(notification: NSNotification) {
        let message = notification.object as! Message
        messages.append(message)
    }
}
