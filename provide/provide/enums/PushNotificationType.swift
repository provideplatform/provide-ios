//
//  PushNotificationType.swift
//  provide
//
//  Created by Jawwad Ahmad on 6/4/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

enum PushNotificationType: String {
    case attachment = "attachment_id"
    case checkin = "checkin"
    case job = "job_id"
    case message = "message"
    case unknown = ""
    case workOrder = "work_order_changed"
    case providerBecameAvailable = "provider_became_available"
    case providerBecameUnavailable = "provider_became_unavailable"
    case providerLocationChanged = "provider_location_changed"

    private var typeKey: String {
        return rawValue
    }

    static let allTypes = [
        attachment,
        checkin,
        job,
        message,
        workOrder,
        providerBecameAvailable,
        providerBecameUnavailable,
        providerLocationChanged,
    ]

    static func typeAndValueFromUserInfo(_ userInfo: [String: Any]) -> (PushNotificationType, Any?) {
        for type in allTypes {
            if let value: Any = userInfo[type.rawValue] {
                return (type, value)
            }
        }
        logWarn("Existing notification type not found in userInfo: \(userInfo)")
        return (unknown, nil)
    }
}
