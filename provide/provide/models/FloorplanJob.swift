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

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromArray([
            "id",
            "floorplan_id",
            "job_id",
            ]
        )
        mapping.addRelationshipMappingWithSourceKeyPath("floorplan", mapping: Floorplan.mapping())
        //mapping.addRelationshipMappingWithSourceKeyPath("job", mapping: Job.mapping())
        return mapping
    }
}
