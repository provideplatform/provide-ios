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
        let mapping = RKObjectMapping(forClass: self)
        return mapping
    }

    override var description: String {
        return "\(toDictionary(false))"
    }

    // Empty init() required by RestKit
    override init() {
        super.init()
    }

    required init(string: String) {
        super.init()

        let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
        let dictionary = decodeJSON(data)

        for (key, var value) in dictionary {
            var camelCaseKey = key.snakeCaseToCamelCaseString()
            if value is NSDictionary {
                if let relationshipMapping = self.dynamicType.self.mapping().propertyMappingsByDestinationKeyPath[camelCaseKey] as? RKRelationshipMapping {
                    let clazz = (relationshipMapping.mapping as! RKObjectMapping).objectClass as! Model.Type
                    value = clazz.init(string: (value as! NSDictionary).toJSON())
                } else {
                    value = value as! NSDictionary
                }
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
        let ivars: UnsafeMutablePointer<Ivar> = class_copyIvarList(self.dynamicType, &count)

        for i in 0..<count {
            var key = NSString(CString: ivar_getName(ivars[Int(i)]), encoding: NSUTF8StringEncoding) as! String
            var value: AnyObject! = valueForKey(key)

            if value != nil {
                if value is Model {
                    value = (value as! Model).toDictionary(snakeKeys)
                } else if value is [Model] {
                    var newValue = [[String : AnyObject]]()
                    for val in value as! [Model] {
                        newValue.append(val.toDictionary(snakeKeys))
                    }
                    value = newValue
                }
            }

            key = snakeKeys ? key.snakeCaseString() : key
            dictionary[key] = value
        }
        
        return dictionary
    }

    func toJSONString(snakeCaseKeys: Bool = false) -> String {
        return toDictionary(false).toJSONString()
    }

    override func setValue(value: AnyObject?, forUndefinedKey key: String) {

    }

    override func valueForUndefinedKey(key: String) -> AnyObject? {
        return nil
    }

    override func validateValue(ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>, forKeyPath inKeyPath: String) throws {
        if ioValue.memory != nil {
            if ioValue.memory is NSNull {
                ioValue.memory = nil
                return
            }
        }
        try super.validateValue(ioValue, forKeyPath: inKeyPath)
    }
}