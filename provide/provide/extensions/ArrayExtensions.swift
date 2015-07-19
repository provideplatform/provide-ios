//
//  ArrayExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

extension Array {

    func each(block: (Element) -> Void) {
        for object in self {
            block(object)
        }
    }

    func findFirst(conditionBlock: (Element) -> Bool) -> Element? {
        for object in self {
            if conditionBlock(object) {
                return object
            }
        }
        return nil
    }

    func indexOfObject<T: Equatable>(obj: T) -> Int? {
        var idx = 0
        for elem in self {
            if obj == elem as! T {
                return idx
            }
            idx++
        }
        return nil
    }

    func toJSON() -> String! {
        let jsonData = encodeJSON(self as! AnyObject)
        return NSString(bytes: jsonData.bytes, length: jsonData.length, encoding: NSUTF8StringEncoding) as! String
    }

    mutating func removeObject<U: Equatable>(object: U) {
        for (index, objectToCompare) in enumerate(self) {
            if let to = objectToCompare as? U {
                if object == to {
                    removeAtIndex(index)
                    break
                }
            }
        }
    }
}
