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
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", withMapping: Attachment.mappingWithRepresentations()))
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

    var blueprintImageUrl: NSURL! {
        if let blueprintImageUrlString = blueprint?.urlString {
            return NSURL(string: blueprintImageUrlString)
        }
        return nil
    }

    var hasPendingBlueprint: Bool {
        if let blueprint = blueprint {
            return blueprint.status == "pending"
        }
        return false
    }

    var blueprints: [Attachment] {
        var blueprints = [Attachment]()
        for attachment in attachments {
            if attachment.hasTag("blueprint") {
                blueprints.append(attachment)
            }
        }
        return blueprints
    }

    weak var blueprint: Attachment! {
        if blueprints.count > 0 {
            for blueprint in blueprints {
                if blueprint.mimeType == "image/png" {
                    return blueprint
                }
            }
        }
        return nil
    }

    func mergeAttachment(attachment: Attachment) {
        if attachments == nil {
            attachments = [Attachment]()
        }

        var replaced = false
        var index = 0
        for a in attachments {
            if a.id == attachment.id {
                self.attachments[index] = attachment
                replaced = true
                break
            }
            index += 1
        }

        if !replaced {
            attachments.append(attachment)
        }
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
