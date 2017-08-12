//
//  UserMode.swift
//  provide
//
//  Created by Kyle Thomas on 8/12/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import KTSwiftExtensions

enum UserMode: String {
    case Customer = "customer"
    case Provider = "provider"

    var typeKey: String {
        return rawValue
    }

    static let allTypes = [Customer, Provider]

    static func typeAndValueFromUserInfo(_ userInfo: [String: AnyObject]) -> (UserMode, AnyObject?) {
        for type in allTypes {
            if let value: AnyObject = userInfo[type.rawValue] {
                return (type, value)
            }
        }
        logInfo("Existing user mode type not found in userInfo: \(userInfo); defaulting to customer...")
        return (Customer, "customer" as AnyObject)  // default to customer
    }
}
