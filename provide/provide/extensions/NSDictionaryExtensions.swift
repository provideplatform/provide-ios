//
//  NSDictionaryExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

extension NSDictionary {

    func toJSON() -> String! {
        var error: NSError?
        if let json = NSJSONSerialization.dataWithJSONObject(self, options: nil, error: &error) {
            return NSString(bytes: json.bytes, length: json.length, encoding: NSUTF8StringEncoding) as! String
        }
        return nil
    }

    func toQueryString() -> String {
        var queryString = ""
        for (key, value) in self {
            var encodedName = (key as! String).urlEncodedString()
            var encodedValue = "\(value)".urlEncodedString()
            var encodedParameter = "\(encodedName)=\(encodedValue)"
            queryString = queryString + (queryString == "" ? "" : "&") + encodedParameter
        }
        return queryString
    }

}
