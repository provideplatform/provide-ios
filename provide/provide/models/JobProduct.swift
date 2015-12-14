//
//  JobProduct.swift
//  provide
//
//  Created by Kyle Thomas on 12/8/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class JobProduct: Model {

    var id = 0
    var jobId = 0
    var job: Job!
    var productId = 0
    var product: Product!
    var initialQuantity = 0.0
    var price = -1.0

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "job_id": "jobId",
            "product_id": "productId",
            "initial_quantity": "initialQuantity",
            "price": "price",
            ])
        mapping.addRelationshipMappingWithSourceKeyPath("product", mapping: Product.mapping())
        return mapping
    }
}
