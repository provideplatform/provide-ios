//
//  Device.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Device: Model {

    var id: NSNumber!
    var apnsDeviceId: String!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "apns_device_id": "apnsDeviceId"
        ])
        return mapping
    }
}
