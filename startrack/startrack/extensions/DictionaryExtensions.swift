//
//  DictionaryExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

extension Dictionary {

    func toJSONString() -> String {
        let jsonData = encodeJSON(self as! AnyObject)
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
