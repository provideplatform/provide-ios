//
//  MessageServiceTests.swift
//  provide
//
//  Created by Jawwad Ahmad on 6/4/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import XCTest
@testable import provide

class MessageServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()

        OHHTTPStubs.onStubActivation() { request, stub in
            logInfo("\(request.URL!) stubbed by \(stub.name!).")
        }

        stubRoute("GET", path: "/api/messages", withFile: "HTTPStubs/messages/conversation.json", stubName: "MessageServiceTests")
    }

    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testFetch() {
        let expectation = self.expectation(description: "GET messages")

        var fetchedMessages = [Message]()
        MessageService.sharedService().fetch(
            onMessagesFetched: { messages in
                fetchedMessages = messages
                expectation.fulfill()
            },
            onError: { error, statusCode, responseString in

            }
        )

        waitForExpectations(timeout: 5) { error in
            XCTAssert(fetchedMessages.count == 16)

            // 3 participants
            XCTAssertEqual(Set(fetchedMessages.map { $0.senderID }).count, 3)

            XCTAssertEqual(fetchedMessages.filter { $0.senderName == "Joe Driver"}.count, 7)
            XCTAssertEqual(fetchedMessages.filter { $0.senderName == "Don Dispatcher"}.count, 6)
            XCTAssertEqual(fetchedMessages.filter { $0.senderName == "Jim Dispatcher"}.count, 3)

            let message = fetchedMessages.first!

            XCTAssertTrue(message.body.hasPrefix("Hey Joe, its Don"))
            let expectedDateString = "2015-05-30T12:01:00Z"
            let expectedDate = DateFormatter(coder: "yyyy-MM-dd'T'HH:mm:ssZZZZZ").dateFromString(expectedDateString)
            XCTAssertEqual(message.createdAt, expectedDate!)
            XCTAssertEqual(message.id, 1)
            XCTAssertEqual(message.recipientId, 2)
            XCTAssertEqual(message.recipientName, "Joe Driver")
            XCTAssertEqual(message.senderID, 1)
            XCTAssertEqual(message.senderName, "Don Dispatcher")

            let expectedProfileImageURL = URL(string: "http://files.gamebanana.com/img/ico/sprays/southpark_spray_cartman_01_copy.jpg")
            XCTAssertEqual(message.senderProfileImageUrl, expectedProfileImageURL)

            let messageWithNullAvatar = fetchedMessages[14]
            XCTAssertNil(messageWithNullAvatar.senderProfileImageUrl)
        }
    }
}
