//
//  UserMode.swift
//  provide
//
//  Created by Kyle Thomas on 8/12/17.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

enum UserMode: String {
    case consumer
    case provider

    private var typeKey: String {
        return rawValue
    }

    static let mode: UserMode? = infoDictionaryValueFor("xAppMode") != "" ? UserMode(rawValue: infoDictionaryValueFor("xAppMode")) : nil

    static let allTypes = [consumer, provider]

    static func typeAndValueFromUserInfo(_ userInfo: [String: Any]) -> (UserMode, Any?) {
        for type in allTypes {
            if let value = userInfo[type.rawValue] {
                return (type, value)
            }
        }
        logInfo("Existing user mode type not found in userInfo: \(userInfo); defaulting to consumer...")
        return (consumer, "consumer")  // default to consumer
    }
}
