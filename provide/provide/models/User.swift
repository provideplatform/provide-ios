//
//  User.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

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
    var menuItemsPreference: NSArray!
    var paymentMethods: [Any]!

    var profileImageUrl: URL! {
        if let profileImageUrlString = profileImageUrlString {
            return URL(string: profileImageUrlString)
        }
        return nil
    }

    var menuItems: [MenuItem]! {
        if let menuItemsPreference = menuItemsPreference {
            var menuItems = [MenuItem]()
            for menuItemPreference in menuItemsPreference {
                if let item = menuItemPreference as? NSDictionary {
                    menuItems.append(MenuItem(item: item as! [String : String]))
                }
            }
            return menuItems
        } else {
            var defaultMenuItems = [MenuItem]()
            defaultMenuItems.append(MenuItem(item: ["label": "History", "storyboard": "Jobs"]))
            return defaultMenuItems
        }
    }

    var hasBeenPromptedToIntegrateQuickbooks: Bool {
        return UserDefaults.standard.bool(forKey: "presentedQuickbooksAuthorizationDialog")
    }

    var hasBeenPromptedToTakeSelfie: Bool {
        return UserDefaults.standard.bool(forKey: "presentedSelfieViewController")
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id": "id",
            "name": "name",
            "email": "email",
            "profile_image_url": "profileImageUrlString",
            "company_ids": "companyIds",
            "provider_ids": "providerIds",
            "default_company_id": "defaultCompanyId",
            "menu_items": "menuItemsPreference",
            "payment_methods": "paymentMethods",
            ])
        mapping?.addRelationshipMapping(withSourceKeyPath: "contact", mapping: Contact.mapping())
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "companies", toKeyPath: "companies", with: Company.mapping()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "providers", toKeyPath: "providers", with: Provider.mapping()))
        return mapping!
    }

    func reload() {
        reload(nil, onError: nil)
    }

    func reload(_ onSuccess: OnSuccess!, onError: OnError!) {
        ApiService.sharedService().fetchUser(
            onSuccess: { statusCode, mappingResult in
                if let onSuccess = onSuccess {
                    onSuccess(statusCode, mappingResult)
                }
            },
            onError: { error, statusCode, responseString in
                if let onError = onError {
                    onError(error, statusCode, responseString)
                }
            }
        )
    }

    func reloadCompanies(_ onSuccess: OnSuccess!, onError: OnError!) {
        let companyIdsQueryString = companyIds.map({ String($0) }).joined(separator: "|")
        let params: [String : AnyObject] = ["id": companyIdsQueryString as AnyObject]
        ApiService.sharedService().fetchCompanies(params,
            onSuccess: { statusCode, mappingResult in
                self.companies = mappingResult?.array() as! [Company]
                if let onSuccess = onSuccess {
                    onSuccess(statusCode, mappingResult)
                }
            },
            onError: { error, statusCode, responseString in
                if let onError = onError {
                    onError(error, statusCode, responseString)
                }
            }
        )
    }
}

// MARK: - Global user

var currentUser: User!
