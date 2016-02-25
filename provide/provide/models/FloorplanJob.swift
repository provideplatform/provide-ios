//
//  FloorplanJob.swift
//  provide
//
//  Created by Kyle Thomas on 2/14/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

class FloorplanJob: Model {

    var id = 0
    var floorplanId = 0
    var jobId = 0
    var floorplan: Floorplan!
    var job: Job!
    var backsplashPartialLf = -1.0
    var backsplashFullLf = -1.0
    var backsplashSqFt = -1.0
    var backsplashLaborPricePerStraightLf = -1.0
    var backsplashLaborPricePerDiagonalLf = -1.0
    var backsplashLaborPricePerRunningBondLf = -1.0
    var flooringMaterialTier1CostPerSqFt = -1.0
    var flooringMaterialTier2CostPerSqFt = -1.0
    var flooringMaterialTier3CostPerSqFt = -1.0

    var supportsBacksplash: Bool {
        return backsplashSqFt != -1 && backsplashFullLf != -1 && backsplashPartialLf != -1
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromArray([
            "id",
            "floorplan_id",
            "job_id",
            "backsplash_partial_lf",
            "backsplash_full_lf",
            "backsplash_sq_ft",
            "backsplash_labor_price_per_straight_lf",
            "backsplash_labor_price_per_diagonal_lf",
            "backsplash_labor_price_per_running_bond_lf",
            "flooring_material_tier1_cost_per_sq_ft",
            "flooring_material_tier2_cost_per_sq_ft",
            "flooring_material_tier3_cost_per_sq_ft",
            ]
        )
        mapping.addRelationshipMappingWithSourceKeyPath("floorplan", mapping: Floorplan.mapping())
        //mapping.addRelationshipMappingWithSourceKeyPath("job", mapping: Job.mapping())
        return mapping
    }
}
