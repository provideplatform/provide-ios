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
    var userId = 0
    var jobId = 0
    var quotedPricePerSqFt: Double!
    var totalSqFt: Double!
    var attachments: [Attachment]!
    var createdAtString: String!
    var updatedAtString: String!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "user_id": "userId",
            "job_id": "jobId",
            "quoted_price_per_sq_ft": "quotedPricePerSqFt",
            "total_sq_ft": "totalSqFt",
            "created_at": "createdAtString",
            "updated_at": "updatedAtString",
            ])
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", withMapping: Attachment.mapping()))
        return mapping
    }

    var amount: Double! {
        if quotedPricePerSqFt == nil || totalSqFt == nil {
            return nil
        }
        return quotedPricePerSqFt * totalSqFt
    }

    var createdAt: NSDate! {
        if let createdAtString = createdAtString {
            return NSDate.fromString(createdAtString)
        }
        return nil
    }

    var humanReadableTotalSqFt: String! {
        if totalSqFt != nil {
            return "\(NSString(format: "%.03f", totalSqFt)) sq ft"
        }
        return nil
    }

    var updatedAt: NSDate! {
        if let updatedAtString = updatedAtString {
            return NSDate.fromString(updatedAtString)
        }
        return nil
    }

    func reload(params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) {
        if jobId > 0 {
            ApiService.sharedService().fetchEstimateWithId(String(id), forJobWithId: String(jobId),
                onSuccess: { statusCode, mappingResult in
                    let estimate = mappingResult.firstObject as! Estimate
                    self.jobId = estimate.jobId
                    self.quotedPricePerSqFt = estimate.quotedPricePerSqFt
                    self.totalSqFt = estimate.totalSqFt
                    self.attachments = estimate.attachments
                    self.updatedAtString = estimate.updatedAtString
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        }
    }
}
