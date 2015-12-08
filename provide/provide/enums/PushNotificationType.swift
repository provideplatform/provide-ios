//
//  PushNotificationType.swift
//  provide
//
//  Created by Jawwad Ahmad on 6/4/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

enum PushNotificationType: String {
    case Attachment = "attachment_id"
    case Checkin = "checkin"
    case Job = "job_id"
    case Message = "message"
    case Route = "route_id"
    case Unknown = ""
    case WorkOrder = "work_order_id"

    var typeKey: String {
        return rawValue
    }

    static let allTypes = [Attachment, Checkin, Job, Message, Route, WorkOrder]

    static func typeAndValueFromUserInfo(userInfo: [String: AnyObject]) -> (PushNotificationType, AnyObject!) {
        for type in allTypes {
            if let value: AnyObject = userInfo[type.rawValue] {
                return (type, value)
            }
        }
        logWarn("Existing notification type not found in userInfo: \(userInfo)")
        return (Unknown, nil)
    }
}
