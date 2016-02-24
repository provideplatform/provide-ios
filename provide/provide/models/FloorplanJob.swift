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

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromArray([
            "id",
            "floorplan_id",
            "job_id",
            "backsplash_partial_lf",
            "backsplash_full_lf",
            "backsplash_sq_ft",
            ]
        )
        mapping.addRelationshipMappingWithSourceKeyPath("floorplan", mapping: Floorplan.mapping())
        //mapping.addRelationshipMappingWithSourceKeyPath("job", mapping: Job.mapping())
        return mapping
    }
}
