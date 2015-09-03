//
//  OHHTTPStubsHelper.swift
//  provide
//
//  Created by Jawwad Ahmad on 6/7/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class OHHTTPStubsHelper {

    static let iso8601DateFormatter: NSDateFormatter = {
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        dateFormatter.timeZone = NSTimeZone(abbreviation: "UTC")
        return dateFormatter
    }()

    func stubMessagesNetworkRequests() {
        stubRoute("GET", path: "/api/messages", withFile: "HTTPStubs/messages/conversation.json")

        // POST messages
        OHHTTPStubs.stubRequestsPassingTest(
            { request in
                return request.URL!.path! == "/api/messages" && request.HTTPMethod == "POST"
            },
            withStubResponse: { request in
                let bodyJson = decodeJSON(request.HTTPBody!)
                let text = bodyJson["body"] as! String
                let recipientId = bodyJson["recipient_id"] as! String

                let responseJSON = [
                    "id": Int(NSDate().timeIntervalSinceDate(NSDate().atMidnight)),
                    "body": text,
                    "recipient_id": Int(recipientId)!,
                    "sender_id": currentUser().id,
                    "created_at": OHHTTPStubsHelper.iso8601DateFormatter.stringFromDate(NSDate()),
                    "recipient_name":"Kyle Thomas",
                    "sender_name": currentUser().name]
                return OHHTTPStubsResponse(JSONObject: responseJSON, statusCode: 201, headers: ["Content-Type":"application/json"]).requestTime(1.0, responseTime: 1.0)
            }
        )
    }
}

func stubRoute(httpMethod: String, path: String, withFile filePath: String, stubName: String? = nil)  {
    OHHTTPStubs.stubRequestsPassingTest(
        { request in
            return request.URL!.path! == path && request.HTTPMethod == httpMethod
        },
        withStubResponse: { request in
            let fixture = OHPathForFile(filePath, OHHTTPStubsHelper.self)
            return OHHTTPStubsResponse(fileAtPath: fixture!, statusCode: 200, headers: ["Content-Type":"application/json"])
        }
    ).name = stubName
}
