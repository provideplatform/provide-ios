//
//  Provider.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Provider: Model {

    var id = 0
    var companyId = 0
    var userId = 0
    var name: String!
    var contact: Contact!
    var profileImageUrlString: String!
    var services: NSSet!

    var profileImageUrl: NSURL? {
        guard let profileImageUrlString = profileImageUrlString else { return nil }
        return NSURL(string: profileImageUrlString)
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "company_id": "companyId",
            "user_id": "userId",
            "name": "name",
            "services": "services",
            "profile_image_url": "profileImageUrlString"
            ])
        mapping.addRelationshipMappingWithSourceKeyPath("contact", mapping: Contact.mapping())
        return mapping
    }

    var firstName: String? {
        if let name = name {
            return name.splitAtString(" ").0
        } else {
            return nil
        }
    }

    var lastName: String? {
        if let name = name {
            return name.splitAtString(" ").1
        } else {
            return nil
        }
    }

    func reload(onSuccess onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().fetchProviderWithId(String(id),
            onSuccess: { statusCode, mappingResult in
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func save(onSuccess onSuccess: OnSuccess, onError: OnError) {
        var params = toDictionary()
        params.removeValueForKey("id")

        if id > 0 {
            ApiService.sharedService().updateProviderWithId(String(id), params: params,
                onSuccess: { statusCode, mappingResult in
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        } else {
            params.removeValueForKey("user_id")

            ApiService.sharedService().createProvider(params,
                onSuccess: { statusCode, mappingResult in
                    let provider = mappingResult.firstObject as! Provider
                    self.id = provider.id
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        }
    }
}
