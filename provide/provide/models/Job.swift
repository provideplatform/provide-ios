//
//  Job.swift
//  provide
//
//  Created by Kyle Thomas on 10/24/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Job: Model {

    var id = 0
    var name: String!
    var companyId = 0
    var company: Company!
    var customerId = 0
    var customer: Customer!
    var attachments: [Attachment]!
    var blueprints: [Attachment]!
    var blueprintImageUrlString: String!
    var blueprintScale = 0.0
    var blueprintAnnotationsCount = 0
    var expenses: [Expense]!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "name": "name",
            "company_id": "companyId",
            "customer_id": "customerId",
            "blueprint_image_url": "blueprintImageUrlString",
            "blueprint_scale": "blueprintScale",
            "blueprint_annotations_count": "blueprintAnnotationsCount",
            ])
        mapping.addRelationshipMappingWithSourceKeyPath("company", mapping: Company.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("customer", mapping: Customer.mapping())
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", withMapping: Attachment.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "blueprints", toKeyPath: "blueprints", withMapping: Attachment.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "expenses", toKeyPath: "expenses", withMapping: Expense.mapping()))
        return mapping
    }

    var blueprintImageUrl: NSURL! {
        if let blueprintImageUrlString = blueprintImageUrlString {
            return NSURL(string: blueprintImageUrlString)
        }
        return nil
    }

    var blueprint: Attachment! {
        if let blueprints = blueprints {
            if blueprints.count > 0 {
                return blueprints.filter({ $0.mimeType == "image/png" }).first!
            }
        }
        return nil
    }

    func updateJobBlueprintScale(blueprintScale: CGFloat, onSuccess: OnSuccess, onError: OnError) {
        if let blueprint = blueprint {
            self.blueprintScale = Double(blueprintScale)

            var metadata = blueprint.metadata.mutableCopy() as! [String : AnyObject]
            metadata["scale"] = blueprintScale
            blueprint.updateAttachment(["metadata": metadata], onSuccess: onSuccess, onError: onError)
        }
    }
}
