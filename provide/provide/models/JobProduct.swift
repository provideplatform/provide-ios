//
//  JobProduct.swift
//  provide
//
//  Created by Kyle Thomas on 12/8/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

class JobProduct: Model {

    var id = 0
    var jobId = 0
    var productId = 0
    var product: Product!
    var initialQuantity = 0.0
    var remainingQuantity = 0.0
    var price = -1.0

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id": "id",
            "job_id": "jobId",
            "product_id": "productId",
            "initial_quantity": "initialQuantity",
            "remaining_quantity": "remainingQuantity",
            "price": "price",
            ])
        mapping?.addRelationshipMapping(withSourceKeyPath: "product", mapping: Product.mapping())
        return mapping!
    }

    var percentageRemaining: CGFloat {
        var percentageRemaining: CGFloat = 0.0
        if remainingQuantity > 0.0 {
            percentageRemaining = CGFloat(remainingQuantity) / CGFloat(initialQuantity)
        }
        return percentageRemaining
    }

    var statusColor: UIColor! {
        var statusColor = UIColor.clear
        if remainingQuantity > 0.0 {
            let percentage = percentageRemaining
            if percentage <= 0.33 {
                statusColor = Color.abandonedStatusColor()
            } else if percentage <= 0.66 {
                statusColor = Color.canceledStatusColor()
            } else {
                statusColor = Color.completedStatusColor()
            }
        }
        return statusColor
    }
}
