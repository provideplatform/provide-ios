//
//  Estimate.swift
//  provide
//
//  Created by Kyle Thomas on 2/2/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Estimate: Model {

    var id = 0
    var quotedPricePerSqFt = -1.0
    var totalSqFt = -1.0

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "quoted_price_per_sq_ft": "quotedPricePerSqFt",
            "total_sq_ft": "totalSqFt",
            ])
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", withMapping: Attachment.mapping()))
        return mapping
    }

    var amount: Double! {
        if quotedPricePerSqFt == -1.0 || totalSqFt == -1.0 {
            return nil
        }
        return quotedPricePerSqFt * totalSqFt
    }
}
