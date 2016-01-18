//
//  Floorplan.swift
//  provide
//
//  Created by Kyle Thomas on 1/18/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Floorplan: Model {

    var id = 0
    var companyId = 0
    var customerId = 0
    var name: String!
    var attachments: [Attachment]!
    var blueprints: [Attachment]!
    var blueprintImageUrlString: String!
    var blueprintScale = 0.0
    var blueprintAnnotationsCount = 0
    var totalSqFt = -1
    var numberOfBedrooms = -1
    var numberOfBathrooms = -1
    var garageSize = -1
    var basePrice = -1.0
    var desc: String!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "company_id": "companyId",
            "customer_id": "customerId",
            "name": "name",
            "blueprint_image_url": "blueprintImageUrlString",
            "blueprint_scale": "blueprintScale",
            "blueprint_annotations_count": "blueprintAnnotationsCount",
            "total_sq_ft": "totalSqFt",
            "number_of_bedrooms": "numberOfBedrooms",
            "number_of_bathrooms": "numberOfBathrooms",
            "garage_size": "garageSize",
            "base_price": "basePrice",
            "description": "desc",
            ])
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", withMapping: Attachment.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "blueprints", toKeyPath: "blueprints", withMapping: Attachment.mapping()))
        return mapping
    }

    var blueprintImageUrl: NSURL! {
        if let blueprintImageUrlString = blueprintImageUrlString {
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

    weak var blueprint: Attachment! {
        if let blueprints = blueprints {
            if blueprints.count > 0 {
                for blueprint in blueprints {
                    if blueprint.mimeType == "image/png" {
                        return blueprint
                    }
                }
            }
        }
        return nil
    }
}
