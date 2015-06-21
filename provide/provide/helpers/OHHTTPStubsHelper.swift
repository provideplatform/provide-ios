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
        let dateFormatter = NSDateFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ssZZZZZ")
        dateFormatter.timeZone = NSTimeZone(abbreviation: "UTC")
        return dateFormatter
    }()

    class func stubMessagesNetworkRequests() {

        // GET messages
        OHHTTPStubs.stubRequestsPassingTest(
            { request in
                return request.URL!.path! == "/api/messages" && request.HTTPMethod == "GET"
            },
            withStubResponse: { request in
                let fixture = OHPathForFile("HTTPStubs/messages/conversation.json", self.dynamicType)
                return OHHTTPStubsResponse(fileAtPath: fixture!, statusCode: 200, headers: ["Content-Type":"application/json"])
            }
        )

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
                    "recipient_id": recipientId.toInt()!,
                    "sender_id": currentUser().id.integerValue,
                    "created_at": self.iso8601DateFormatter.stringFromDate(NSDate()),
                    "recipient_name":"Kyle Thomas",
                    "sender_name": currentUser().name]
                return OHHTTPStubsResponse(JSONObject: responseJSON, statusCode: 201, headers: ["Content-Type":"application/json"]).requestTime(1.0, responseTime: 1.0)
            }
        )
    }
}
