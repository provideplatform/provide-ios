//
//  Model.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Model: NSObject, Printable {

    class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        return mapping
    }

    override var description: String {
        return "\(toDictionary(snakeKeys: false))"
    }

    // Empty init() required by RestKit
    override init() {
        super.init()
    }

    required init(string: String!) {
        super.init()

        let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
        let dictionary = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) as! [String: AnyObject]

        for (key, var value) in dictionary {
            var camelCaseKey = key.snakeCaseToCamelCaseString()
            if value is NSDictionary {
                let relationshipMapping = self.dynamicType.self.mapping().propertyMappingsByDestinationKeyPath[camelCaseKey] as! RKRelationshipMapping
                let clazz = (relationshipMapping.mapping as! RKObjectMapping).objectClass as! Model.Type
                value = clazz(string: (value as! NSDictionary).toJSON())
            }

            if camelCaseKey == "senderId" {
                camelCaseKey = "senderID" // HACK to accommodate creating a Message object
            }

            setValue(value, forKey: camelCaseKey)
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
            dictionary[key] = value != nil && value is Model ? (value as! Model).toDictionary(snakeKeys: snakeKeys) : value
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
