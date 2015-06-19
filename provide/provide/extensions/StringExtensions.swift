//
//  StringExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

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
        return replaceString(" ", withString: "+").stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
    }

    func splitAtString(seperator: String) -> (String, String) {
        let components = componentsSeparatedByString(seperator)
        assert(components.count == 2, "This method can only return a tuple containing 2 values")
        return (components[0], components[1])
    }

    private func toJSONAnyObject() -> AnyObject! {
        let data = dataUsingEncoding(NSUTF8StringEncoding)
        let jsonObject: AnyObject?
        do {
            jsonObject = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
        } catch let error as NSError {
            logError("Error converting String to JSONObject : \(error.localizedDescription)")
            jsonObject = nil
        }

        return jsonObject
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
        return pattern.stringByReplacingMatchesInString(self, options: [], range: NSMakeRange(0, self.characters.count), withTemplate: "$1_$2").lowercaseString
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

    func isValidForEmail() -> Bool {
        let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let test = NSPredicate(format:"SELF MATCHES %@", regex)
        return test.evaluateWithObject(self)
    }

    func isValidForPassword() -> Bool {
        let validLength = 8 <= length
        let noSpaces = !contains(" ")
        let noCommas = !contains(",")
        let hasNumber = containsOneOrMoreNumbers()
        let hasUpper = containsOneOrMoreUppercaseLetters()
        let hasLower = containsOneOrMoreLowercaseLetters()

        return validLength && noSpaces && noCommas && hasNumber && hasUpper && hasLower
    }

    func isDigits() -> Bool {
        let nonDigits = NSCharacterSet.decimalDigitCharacterSet().invertedSet
        return rangeOfCharacterFromSet(nonDigits) == nil
    }

    func stringByStrippingHTML() -> String! {
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
