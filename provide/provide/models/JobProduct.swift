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
    var productId = 0
    var product: Product!
    var initialQuantity = 0.0
    var remainingQuantity = 0.0
    var price = -1.0
    var flooringMaterialTier1CostPerSqFt = -1.0
    var flooringMaterialTier2CostPerSqFt = -1.0
    var flooringMaterialTier3CostPerSqFt = -1.0

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "job_id": "jobId",
            "product_id": "productId",
            "initial_quantity": "initialQuantity",
            "remaining_quantity": "remainingQuantity",
            "price": "price",
            "flooring_material_tier1_cost_per_sq_ft": "flooringMaterialTier1CostPerSqFt",
            "flooring_material_tier2_cost_per_sq_ft": "flooringMaterialTier2CostPerSqFt",
            "flooring_material_tier3_cost_per_sq_ft": "flooringMaterialTier3CostPerSqFt",
            ])
        mapping.addRelationshipMappingWithSourceKeyPath("product", mapping: Product.mapping())
        return mapping
    }

    var percentageRemaining: CGFloat {
        var percentageRemaining: CGFloat = 0.0
        if remainingQuantity > 0.0 {
            percentageRemaining = CGFloat(remainingQuantity) / CGFloat(initialQuantity)
        }
        return percentageRemaining
    }

    var statusColor: UIColor! {
        var statusColor = UIColor.clearColor()
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
