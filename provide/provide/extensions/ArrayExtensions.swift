//
//  ArrayExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

extension Array {

    func each(block: (T) -> Void) {
        for object in self {
            block(object)
        }
    }

    func findFirst(conditionBlock: (T) -> Bool) -> T? {
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

    mutating func removeObject<U: Equatable>(object: U) {
        var index: Int?
        for (idx, objectToCompare) in self.enumerate() {
            if let to = objectToCompare as? U {
                if object == to {
                    index = idx
                    break
                }
            }
        }

        if index != nil {
            removeAtIndex(index!)
        }
    }
}
