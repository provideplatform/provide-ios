//
//  Device.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

class Device: Model {

    var id = 0
    var apnsDeviceId: String!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromArray([
            "id",
            "apns_device_id",
            ]
        )
        return mapping
    }
}
