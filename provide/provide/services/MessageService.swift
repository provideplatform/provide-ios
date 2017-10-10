//
//  MessagesService.swift
//  provide
//
//  Created by Jawwad Ahmad on 6/4/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnMessagesFetched = (_ messages: [Message]) -> Void
typealias OnMessageCreated = (Message) -> Void

class MessageService {
    static let shared = MessageService()

    private var messages = [Message]()

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleNewMessageReceived(_:)), name: "NewMessageReceivedNotification")
    }

    func fetch(params: [String: Any], onMessagesFetched: @escaping OnMessagesFetched, onError: @escaping OnError) {
        ApiService.shared.fetchMessages(params, onSuccess: { statusCode, mappingResult in
            let fetchedMessages = mappingResult?.array() as! [Message]
            self.messages += fetchedMessages
            onMessagesFetched(fetchedMessages)
        }, onError: onError)
    }

    func createMessage(_ text: String, recipientId: Int, onMessageCreated: @escaping OnMessageCreated, onError: @escaping OnError) {
        ApiService.shared.createMessage(["body": text, "recipient_id": recipientId], onSuccess: { statusCode, mappingResult in
            let message = mappingResult?.firstObject as! Message
            self.messages.append(message)
            onMessageCreated(message)
        }, onError: onError)
    }

    @objc private func handleNewMessageReceived(_ notification: Notification) {
        let message = notification.object as! Message
        messages.append(message)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
