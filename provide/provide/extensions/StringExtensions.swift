//
//  StringExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

infix operator =~ { associativity right precedence 90 }
func =~ (input: String, pattern: String) -> Bool {
    return Regex(pattern).test(input)
}

extension String {

    var length: Int {
        return lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
    }

    func replaceString(target: String, withString replacementString: String) -> String {
        return stringByReplacingOccurrencesOfString(target, withString: replacementString)
    }

    var base64EncodedString: String {
        return NSData(bytes: (self as NSString).UTF8String, length: length).base64EncodedStringWithOptions([])
    }

    func urlEncodedString() -> String {
        return replaceString(" ", withString: "+").stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
    }

    func splitAtString(seperator: String, assertedComponentsCount: Int! = 2) -> (String, String) {
        var components = componentsSeparatedByString(seperator)
        if let assertedComponentsCount = assertedComponentsCount {
            if assertedComponentsCount == 2 {
                assert(components.count == assertedComponentsCount, "This method can only return a tuple containing 2 values")
            } else {
                assert(components.count == assertedComponentsCount, "This method expected to find \(assertedComponentsCount) and return a tuple containing 2 values")
                var i = 1
                var aggregateComponent = components[i]
                i += 1
                while i < components.count - 1 {
                    aggregateComponent = "\(aggregateComponent)\(seperator)\(components[i])"
                    i += 1
                }
                components[1] = aggregateComponent
            }
        }
        if components.count == 2 {
            return (components[0], components[1])
        } else if components.count == 1 {
            return (components[0], "")
        }
        return ("", "")
    }

    private func toJSONAnyObject() -> AnyObject! {
        do {
            let data = dataUsingEncoding(NSUTF8StringEncoding)
            let jsonObject: AnyObject? = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers)
            return jsonObject
        } catch let error as NSError {
            logWarn(error.localizedDescription)
            return nil
        }
    }

    func toJSONArray() -> [AnyObject]! {
        if let arr = toJSONAnyObject() as? [AnyObject] {
            return arr as [AnyObject]
        }
        return nil
    }

    func toJSONObject() -> [String : AnyObject]! {
        if let obj = toJSONAnyObject() as? [String : AnyObject] {
            return obj as [String : AnyObject]
        }
        return nil
    }

    func snakeCaseToCamelCaseString() -> String {
        let items: [String] = componentsSeparatedByString("_")
        var camelCase = ""
        var isFirst = true
        for item: String in items {
            if isFirst {
                isFirst = false
                camelCase += item
            } else {
                camelCase += item.capitalizedString
            }
        }
        return camelCase
    }

    func snakeCaseString() -> String {
        let pattern = try! NSRegularExpression(pattern: "([a-z])([A-Z])", options: [])
        return pattern.stringByReplacingMatchesInString(self, options: [], range: NSMakeRange(0, characters.count), withTemplate: "$1_$2").lowercaseString
    }

    var containsNonASCIICharacters: Bool {
        return !canBeConvertedToEncoding(NSASCIIStringEncoding)
    }

    // MARK: Validation Methods

    func contains(searchString: String) -> Bool {
        return rangeOfString(searchString) != nil
    }

    func containsRegex(searchString: String) -> Bool {
        return rangeOfString(searchString, options: .RegularExpressionSearch) != nil
    }

    func containsOneOrMoreNumbers() -> Bool {
        return rangeOfCharacterFromSet(NSCharacterSet.decimalDigitCharacterSet()) != nil
    }

    func containsOneOrMoreUppercaseLetters() -> Bool {
        return rangeOfCharacterFromSet(NSCharacterSet.uppercaseLetterCharacterSet()) != nil
    }

    func containsOneOrMoreLowercaseLetters() -> Bool {
        return rangeOfCharacterFromSet(NSCharacterSet.lowercaseLetterCharacterSet()) != nil
    }

    func isDigit() -> Bool {
        let int = Int(self)
        return (length == 1) && (int >= 0) && (int <= 9)
    }

    func isValidForEmail() -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let test = NSPredicate(format:"SELF MATCHES %@", regex)
        return test.evaluateWithObject(self)
    }

    func stringByStrippingHTML() -> String {
        var range = NSMakeRange(0, 0)
        var str = NSString(string: self)
        while range.location != NSNotFound {
            range = str.rangeOfString("<[^>]+>", options: NSStringCompareOptions.RegularExpressionSearch)
            if range.location != NSNotFound {
                str = str.stringByReplacingCharactersInRange(range, withString: "")
            }
        }
        return str as String
    }
}
