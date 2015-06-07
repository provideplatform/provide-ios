//
//  PushNotificationType.swift
//  provide
//
//  Created by Jawwad Ahmad on 6/4/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

enum PushNotificationType: String {
    case CheckIn = "checkin"
    case Message = "message"
    case WorkOrder = "work_order_id"

    var typeKey: String {
        return rawValue
    }

    static let allTypes = [CheckIn, Message, WorkOrder]

    static func typeAndValueFromUserInfo(userInfo: [String: AnyObject]) -> (PushNotificationType, AnyObject) {
        for type in allTypes {
            if let value: AnyObject = userInfo[type.rawValue] {
                return (type, value)
            }
        }
        fatalError("Existing notification type not found in userInfo: \(userInfo)")
    }
}
