//
//  Regex.swift
//  provide
//
//  Created by Kyle Thomas on 11/10/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Regex {

    class func match(pattern: String, input: String) -> [NSTextCheckingResult] {
        return Regex(pattern).match(input)
    }

    let internalExpression: NSRegularExpression!
    let pattern: String

    init(_ pattern: String) {
        self.pattern = pattern

        do {
            internalExpression = try NSRegularExpression(pattern: pattern, options: .CaseInsensitive)
        } catch let error as NSError {
            internalExpression = nil
            logWarn(error.localizedDescription)
        }
    }

    func match(input: String) -> [NSTextCheckingResult] {
        var matches = [NSTextCheckingResult]()
        if let internalExpression = internalExpression {
            matches = internalExpression.matchesInString(input, options: .Anchored, range: NSMakeRange(0, input.length))
        }
        return matches
    }

    func test(input: String) -> Bool {
        return match(input).count > 0
    }
}
