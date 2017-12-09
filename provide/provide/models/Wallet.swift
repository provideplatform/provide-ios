//
//  Wallet.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

@objcMembers
class Wallet: Model {

    var id = 0
    var type: String!
    var address: String!
    var balance: Double!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id",
            "type",
            "address",
            "balance",
        ])
        return mapping!
    }
}
