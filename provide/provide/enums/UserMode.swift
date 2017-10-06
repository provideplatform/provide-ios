//
//  UserMode.swift
//  provide
//
//  Created by Kyle Thomas on 8/12/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

enum UserMode: String {
    case customer
    case provider

    var typeKey: String {
        return rawValue
    }

    static let allTypes = [customer, provider]

    static func typeAndValueFromUserInfo(_ userInfo: [String: AnyObject]) -> (UserMode, AnyObject?) {
        for type in allTypes {
            if let value: AnyObject = userInfo[type.rawValue] {
                return (type, value)
            }
        }
        logInfo("Existing user mode type not found in userInfo: \(userInfo); defaulting to customer...")
        return (customer, "customer" as AnyObject)  // default to customer
    }
}
