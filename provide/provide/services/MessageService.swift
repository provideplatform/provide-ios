//
//  MessagesService.swift
//  provide
//
//  Created by Jawwad Ahmad on 6/4/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnMessagesFetched = (messages: [Message]) -> ()

class MessageService: NSObject {

    private var messages = [Message]()

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

}
