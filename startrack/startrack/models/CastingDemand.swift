//
//  CastingDemand.swift
//  startrack
//
//  Created by Kyle Thomas on 9/12/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class CastingDemand: Model {

    var id = 0
    var actingRole: ActingRole!
    var shooting: Shooting!
    var quantity = 0
    var quantityRemaining = 0
    var estimatedDuration = 8
    var rate = 0.0
    var scheduledStartAt: String!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromArray([
            "id",
            "quantity",
            "rate",
            ]
        )
        mapping.addAttributeMappingsFromDictionary([
            "quantity_remaining": "quantityRemaining",
            "estimated_duration": "estimatedDuration",
            "scheduled_start_at": "scheduledStartAt",
            ])
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "acting_role", toKeyPath: "actingRole", withMapping: ActingRole.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "shooting", toKeyPath: "shooting", withMapping: Shooting.mapping()))
        return mapping
    }

    var scheduledStartAtDate: NSDate! {
        if let scheduledStartAt = scheduledStartAt {
            return NSDate.fromString(scheduledStartAt)
        }
        return nil
    }

    var humanReadableScheduledStartAtTimestamp: String! {
        if let scheduledStartAtDate = scheduledStartAtDate {
            return "\(scheduledStartAtDate.dayOfWeek), \(scheduledStartAtDate.monthName) \(scheduledStartAtDate.dayOfMonth) @ \(scheduledStartAtDate.timeString!)"
        }
        return nil
    }

    func fetchProviderRecommendations(onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().fetchProviderRecommendationsForCastingDemandWithId(String(id),
            onSuccess: { (statusCode, mappingResult) -> () in
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }
}
