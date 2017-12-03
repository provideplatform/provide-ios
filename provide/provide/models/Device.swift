//
//  Device.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

@objcMembers
class Device: Model {

    var id = 0
    var apnsDeviceId: String!
    var bundleId: String!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id",
            "apns_device_id",
            "bundle_id",
        ])
        return mapping!
    }
}
