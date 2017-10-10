//
//  Model.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

@objcMembers
class Model: NSObject {

    class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        return mapping!
    }

    var ivars: [String] {
        var count: UInt32 = 0
        let ivars: UnsafeMutablePointer<OpaquePointer> = class_copyIvarList(type(of: self), &count)!

        var ivarStrings = [String]()
        for i in 0..<count {
            let key = (NSString(cString: ivar_getName(ivars[Int(i)])!, encoding: String.Encoding.utf8.rawValue)! as String) as String
            ivarStrings.append(key)
        }
        ivars.deallocate(capacity: Int(count))
        return ivarStrings
    }

    var lastRefreshDate: Date!

    func timeIntervalSinceLastRefreshDate() -> TimeInterval {
        if let lastRefreshDate = lastRefreshDate {
            return abs(lastRefreshDate.timeIntervalSinceNow)
        }
        return -1.0
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

        let data = string.data(using: String.Encoding.utf8)!
        let dictionary = decodeJSON(data)

        for (key, var value) in dictionary {
            var camelCaseKey = key.snakeCaseToCamelCaseString()

            var clazz: Model.Type?
            if let relationshipMapping = type(of: self).self.mapping().propertyMappingsByDestinationKeyPath[camelCaseKey] as? RKRelationshipMapping {
                clazz = (relationshipMapping.mapping as! RKObjectMapping).objectClass as? Model.Type
            }

            if value is NSDictionary {
                if let clazz = clazz {
                    value = clazz.init(string: (value as! NSDictionary).toJSON())
                } else {
                    value = value as! NSDictionary
                }
            } else if value is NSArray {
                if let clazz = clazz {
                    var newValue = [Model]()
                    for v in value as! NSArray {
                        newValue.append(clazz.init(string: (v as! NSDictionary).toJSON()))
                    }
                    value = newValue as AnyObject
                } else {
                    value = value as! NSArray
                }
            }

            if camelCaseKey == "senderId" {
                camelCaseKey = "senderID" // HACK to accommodate creating a Message object
            }

            if !(value is NSNull) {
                setValue(value, forKey: camelCaseKey)
            }
        }
    }

    func toDictionary(_ snakeKeys: Bool = true, includeNils: Bool = false, ignoreKeys: [String] = [String]()) -> [String: Any] {
        var dictionary = [String: Any]()

        for ivar in ivars {
            var key = ivar
            var value: Any = NSNull()

            if ignoreKeys.index(of: key) == nil {
                if let unwrappedValue = self.value(forKey: key) {
                    value = unwrappedValue
                    if value is Model {
                        value = (value as! Model).toDictionary(snakeKeys)
                    } else if value is [Model] {
                        var newValue = [Any]()
                        for val in value as! [Model] {
                            newValue.append(val.toDictionary(snakeKeys))
                        }
                        value = newValue
                    }
                }

                if !(value is NSNull) || includeNils {
                    key = snakeKeys ? key.snakeCaseString() : key
                    dictionary[key] = value
                }
            }
        }

        if let id = dictionary["id"] as? Int, id == 0 {
            dictionary.removeValue(forKey: "id")
        }

        return dictionary
    }

    func toJSONString(_ snakeCaseKeys: Bool = false) -> String {
        return toDictionary(false).toJSONString()
    }

    override func setValue(_ value: Any?, forUndefinedKey key: String) {

    }

    override func value(forUndefinedKey key: String) -> Any? {
        return nil
    }

    override func validateValue(_ ioValue: AutoreleasingUnsafeMutablePointer<AnyObject?>, forKeyPath inKeyPath: String) throws {
        if ioValue.pointee != nil {
            if ioValue.pointee is NSNull {
                ioValue.pointee = nil
                return
            }
        }
        lastRefreshDate = Date()
        try super.validateValue(ioValue, forKeyPath: inKeyPath)
    }
}
