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

    internal var ivars: [String] {
        var count: UInt32 = 0
        let ivars: UnsafeMutablePointer<Ivar> = class_copyIvarList(self.dynamicType, &count)

        var ivarStrings = [String]()
        for i in 0..<count {
            let key = NSString(CString: ivar_getName(ivars[Int(i)]), encoding: NSUTF8StringEncoding) as! String
            ivarStrings.append(key)
        }
        return ivarStrings
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

        for ivar in ivars {
            var key = ivar
            var value: AnyObject = NSNull()

            if let unwrappedValue = valueForKey(key) {
                value = unwrappedValue
                if value is Model {
                    value = (value as! Model).toDictionary(snakeKeys)
                } else if value is [Model] {
                    var newValue = [AnyObject]()
                    for val in value as! [Model] {
                        newValue.append(val.toDictionary(snakeKeys))
                    }
                    value = newValue
                }
            }

            key = snakeKeys ? key.snakeCaseString() : key
            dictionary[key] = value
        }

        if let id = dictionary["id"] as? Int {
            if id == 0 {
                dictionary.removeValueForKey("id")
            }
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
