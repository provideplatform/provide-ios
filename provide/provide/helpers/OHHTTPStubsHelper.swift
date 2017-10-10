//
//  OHHTTPStubsHelper.swift
//  provide
//
//  Created by Jawwad Ahmad on 6/7/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import OHHTTPStubs

class OHHTTPStubsHelper {

    static let iso8601DateFormatter: DateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        return dateFormatter
    }()

    func stubMessagesNetworkRequests() {
        stubRoute("GET", path: "/api/messages", withFile: "HTTPStubs/messages/conversation.json")

        // POST messages
        OHHTTPStubs.stubRequests(passingTest: { request in
            return request.url!.path == "/api/messages" && request.httpMethod == "POST"
        }, withStubResponse: { request in
            let bodyJson = decodeJSON(request.httpBody!)
            let text = bodyJson["body"] as! String
            let recipientId = bodyJson["recipient_id"] as! String

            let responseJSON: [String: Any] = [
                "id": Int(NSDate().timeIntervalSince(Date().atMidnight)),
                "body": text,
                "recipient_id": Int(recipientId)!,
                "sender_id": currentUser.id,
                "created_at": OHHTTPStubsHelper.iso8601DateFormatter.string(from: Date()),
                "recipient_name": "Kyle Thomas",
                "sender_name": currentUser.name,
            ]
            return OHHTTPStubsResponse(jsonObject: responseJSON, statusCode: 201, headers: ["Content-Type": "application/json"]).requestTime(1.0, responseTime: 1.0)
        })
    }
}

func stubRoute(_ httpMethod: String, path: String, withFile filePath: String, stubName: String? = nil) {
    OHHTTPStubs.stubRequests(passingTest: { request in
        return request.url!.path == path && request.httpMethod == httpMethod
    }, withStubResponse: { request in
        let fixture = OHPathForFile(filePath, OHHTTPStubsHelper.self)
        return OHHTTPStubsResponse(fileAtPath: fixture!, statusCode: 200, headers: ["Content-Type": "application/json"])
    }).name = stubName
}
