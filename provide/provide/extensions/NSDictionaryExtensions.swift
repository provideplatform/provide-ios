//
//  NSDictionaryExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 8/18/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

extension NSDictionary {

    func toJSON() -> String! {
        let jsonData = encodeJSON(self)
        return NSString(bytes: jsonData.bytes, length: jsonData.length, encoding: NSUTF8StringEncoding) as! String
    }

    func toQueryString() -> String {
        var queryString = ""
        for (key, value) in self {
            let encodedName = (key as! String).urlEncodedString()
            let encodedValue = "\(value)".urlEncodedString()
            let encodedParameter = "\(encodedName)=\(encodedValue)"
            queryString = queryString + (queryString == "" ? "" : "&") + encodedParameter
        }
        return queryString
    }
}
