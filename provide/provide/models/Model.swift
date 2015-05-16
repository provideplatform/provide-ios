//
//  Model.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Model: NSObject {

    override init() {
        super.init()
    }

    init(string: String!) {
        super.init()

        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        var obj: AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil)

        if let dictionary = obj as? NSDictionary {
            for key in dictionary.allKeys {
                if let value: AnyObject = dictionary.objectForKey(key) {
                    setValue(value, forKey: key as! String)
                }
            }
        }
    }

    func toDictionary() -> [String : AnyObject] {
        var dictionary = [String : AnyObject]()

        var count: UInt32 = 0
        var ivars: UnsafeMutablePointer<Ivar> = class_copyIvarList(self.dynamicType, &count)

        for i in 0..<count {
            let key = NSString(CString: ivar_getName(ivars[Int(i)]), encoding: NSUTF8StringEncoding) as! String
            var value: AnyObject! = valueForKey(key)
            dictionary[key] = value != nil && value.isKindOfClass(Model) ? value.toDictionary() : value
        }

        return dictionary
    }

    func toJSONString() -> String! {
        return (toDictionary() as NSDictionary).toJSON()
    }

    override func validateValue(ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>, forKeyPath inKeyPath: String, error outError: NSErrorPointer) -> Bool {
        if let memory: AnyObject = ioValue.memory {
            if ioValue.memory is NSNull {
                ioValue.memory = nil
                return true
            }
        }
        return super.validateValue(ioValue, forKeyPath: inKeyPath, error: outError)
    }

}
