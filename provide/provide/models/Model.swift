//
//  Model.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Model: NSObject {

    class func mapping() -> RKObjectMapping {
        var mapping = RKObjectMapping(forClass: self)
        return mapping
    }

    override init() {
        super.init()
    }

    required init(string: String!) {
        super.init()

        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        var obj: AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil)

        if let dictionary = obj as? NSDictionary {
            for snakeKey in dictionary.allKeys {
                let key = (snakeKey as! String).snakeCaseToCamelCaseString()
                if let obj: AnyObject = dictionary.objectForKey(snakeKey) {
                    var value: AnyObject = obj

                    if value.isKindOfClass(NSDictionary) {
                        if let mapping = self.dynamicType.self.mapping().propertyMappingsByDestinationKeyPath[key] as? RKRelationshipMapping {
                            let pattern = NSRegularExpression(pattern: "objectClass=(.*) ", options: nil, error: nil)!
                            let range = pattern.firstMatchInString(mapping.mapping.description, options: nil, range: NSMakeRange(0, mapping.mapping.description.length))!.range
                            var className = ((mapping.mapping.description as NSString).substringWithRange(range) as NSString).substringFromIndex(12)
                            className = (className as NSString).substringToIndex(className.length - 1)
                            if let clazz = NSClassFromString(className) as? Model.Type {
                                value = clazz(string: (value as! NSDictionary).toJSON())
                            }
                        }
                    }

                    setValue(value, forKey: key)
                }
            }
        }
    }

    func toDictionary(snakeKeys: Bool = true) -> [String : AnyObject] {
        var dictionary = [String : AnyObject]()

        var count: UInt32 = 0
        var ivars: UnsafeMutablePointer<Ivar> = class_copyIvarList(self.dynamicType, &count)

        for i in 0..<count {
            var key = NSString(CString: ivar_getName(ivars[Int(i)]), encoding: NSUTF8StringEncoding) as! String
            var value: AnyObject! = valueForKey(key)
            key = snakeKeys ? key.snakeCaseString() : key
            dictionary[key] = value != nil && value.isKindOfClass(Model) ? (value as! Model).toDictionary() : value
        }

        return dictionary
    }

    func toJSONString(snakeCaseKeys: Bool = false) -> String! {
        return (toDictionary(snakeKeys: false) as NSDictionary).toJSON()
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
