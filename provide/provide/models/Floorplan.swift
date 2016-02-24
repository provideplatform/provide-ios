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
    var backsplashProductOptions: [Product]!
    var flooringProductOptions: [Product]!
    var totalSqFt = -1.0
    var numberOfBedrooms = -1
    var numberOfBathrooms = -1
    var garageSize = -1
    var basePrice = -1.0
    var backsplashPartialLf = -1.0
    var backsplashFullLf = -1.0
    var backsplashSqFt = -1.0
    var desc: String!
    var profileImageUrlString: String!

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
            "backsplash_partial_lf": "backsplashPartialLf",
            "backsplash_full_lf": "backsplashFullLf",
            "backsplash_sq_ft": "backsplashSqFt",
            "description": "desc",
            "profile_image_url": "profileImageUrlString",
            ])
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", withMapping: Attachment.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "blueprints", toKeyPath: "blueprints", withMapping: Attachment.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "backsplash_product_options", toKeyPath: "backsplashProductOptions", withMapping: Product.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "flooring_product_options", toKeyPath: "flooringProductOptions", withMapping: Product.mapping()))
        return mapping
    }

    var profileImageUrl: NSURL! {
        if let profileImageUrlString = profileImageUrlString {
            return NSURL(string: profileImageUrlString)
        }
        return nil
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

    var requiresBacksplashInstallation: Bool {
        if let backsplashProductOptions = backsplashProductOptions {
            return backsplashProductOptions.count > 0 && backsplashPartialLf != -1.0 && backsplashFullLf != -1.0
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

    func save(onSuccess onSuccess: OnSuccess, onError: OnError) {
        var params = toDictionary()
        params.removeValueForKey("id")

        if id > 0 {
            ApiService.sharedService().updateFloorplanWithId(String(id), params: params,
                onSuccess: { statusCode, mappingResult in
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        } else {
            ApiService.sharedService().createFloorplan(params,
                onSuccess: { statusCode, mappingResult in
                    let floorplan = mappingResult.firstObject as! Floorplan
                    self.id = floorplan.id
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        }
    }
}
