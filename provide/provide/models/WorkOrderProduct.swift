//
//  WorkOrderProduct.swift
//  provide
//
//  Created by Kyle Thomas on 12/8/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class WorkOrderProduct: Model {

    var id = 0
    var workOrderId = 0
    var workorder: WorkOrder!
    var jobProductId = 0
    var jobProduct: JobProduct!
    var quantity = 0.0
    var price = 0.0

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id": "id",
            "work_order_id": "workOrderId",
            "job_product_id": "jobProductId",
            "quantity": "quantity",
            "price": "price",
            ])
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "job_product", toKeyPath: "jobProduct", with: JobProduct.mapping()))
        return mapping!
    }
}
