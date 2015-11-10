//
//  Regex.swift
//  provide
//
//  Created by Kyle Thomas on 11/10/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Regex {

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

    func test(input: String) -> Bool {
        var matches = []
        if let internalExpression = internalExpression {
            matches = internalExpression.matchesInString(input, options: .Anchored, range: NSMakeRange(0, input.length))
        }
        return matches.count > 0
    }
}
