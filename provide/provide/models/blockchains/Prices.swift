//
//  Prices.swift
//  provide
//
//  Created by Kyle Thomas on 12/24/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

@objcMembers
class Prices: Model {

    var btcusd: Double = 0
    var ethusd: Double = 0
    var ltcusd: Double = 0
    var prvdusd: Double = 0

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "btcusd",
            "ethusd",
            "ltcusd",
            "prvdusd",
        ])
        return mapping!
    }
}
