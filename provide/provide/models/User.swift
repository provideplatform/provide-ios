//
//  User.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class User: Model {

    var id = 0
    var name: String!
    var email: String!
    var profileImageUrlString: String!
    var contact: Contact!
    var companies: [Company]!
    var companyIds = [Int]()
    var providers: [Provider]!
    var providerIds = [Int]()
    var defaultCompanyId = 0

    var profileImageUrl: NSURL! {
        if let profileImageUrlString = profileImageUrlString {
            return NSURL(string: profileImageUrlString)
        }
        return nil
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "name": "name",
            "email": "email",
            "profile_image_url": "profileImageUrlString",
            "company_ids": "companyIds",
            "provider_ids": "providerIds",
            "default_company_id": "defaultCompanyId",
            ])
        mapping.addRelationshipMappingWithSourceKeyPath("contact", mapping: Contact.mapping())
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "companies", toKeyPath: "companies", withMapping: Company.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "providers", toKeyPath: "providers", withMapping: Provider.mapping()))
        return mapping
    }

    func reload() {
        reload(nil, onError: nil)
    }

    func reload(onSuccess: OnSuccess!, onError: OnError!) {
        ApiService.sharedService().fetchUser(
            onSuccess: { statusCode, mappingResult in
                if let onSuccess = onSuccess {
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                }
            },
            onError: { error, statusCode, responseString in
                if let onError = onError {
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            }
        )
    }

    func reloadProviders(onSuccess: OnSuccess!, onError: OnError!) {
        let providerIdsQueryString = providerIds.map({ String($0) }).joinWithSeparator("|")
        let params: [String : AnyObject] = ["id": providerIdsQueryString]
        ApiService.sharedService().fetchProviders(params,
            onSuccess: { statusCode, mappingResult in
                self.providers = mappingResult.array() as! [Provider]
                if let onSuccess = onSuccess {
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                }
            },
            onError: { error, statusCode, responseString in
                if let onError = onError {
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            }
        )
    }
}

// MARK: - Functions

func currentUser() -> User {
    var user: User!
    while user == nil {
        if let token = KeyChainService.sharedService().token {
            user = token.user
        }
    }
    return user
}
