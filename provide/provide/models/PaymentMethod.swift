//
//  PaymentMethod.swift
//  provide
//
//  Created by Kyle Thomas on 9/15/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import Foundation

class PaymentMethod: Model {

    private var id = 0
    private var brand: String!
    private var last4: String!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id",
            "brand",
            "last4",
        ])
        return mapping!
    }
}
