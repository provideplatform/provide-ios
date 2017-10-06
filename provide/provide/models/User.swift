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
    var lastCheckinAt: String!
    var lastCheckinLatitude: NSNumber!
    var lastCheckinLongitude: NSNumber!
    var lastCheckinHeading: NSNumber!

    var annotation: Annotation {
        return Annotation(user: self)
    }

    var coordinate: CLLocationCoordinate2D! {
        if lastCheckinLatitude != nil && lastCheckinLongitude != nil {
            return CLLocationCoordinate2DMake(lastCheckinLatitude.doubleValue, lastCheckinLongitude.doubleValue)
        }
        return nil
    }

    var profileImageUrl: URL! {
        if let profileImageUrlString = profileImageUrlString {
            return URL(string: profileImageUrlString)
        }
        return nil
    }

    var firstName: String? {
        return name?.components(separatedBy: " ").first
    }

    var lastName: String? {
        guard let name = name else { return nil }
        if name.components(separatedBy: " ").count > 1 {
            return name.components(separatedBy: " ").last!
        } else {
            return nil
        }
    }

    var menuItems: [MenuItem]! {
        if let menuItemsPreference = menuItemsPreference {
            var menuItems = [MenuItem]()
            for menuItemPreference in menuItemsPreference {
                if let item = menuItemPreference as? NSDictionary {
                    menuItems.append(MenuItem(item: item as! [String: String]))
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
            "last_checkin_at": "lastCheckinAt",
            "last_checkin_latitude": "lastCheckinLatitude",
            "last_checkin_longitude": "lastCheckinLongitude",
            "last_checkin_heading": "lastcheckinHeading",
            ])
        mapping?.addRelationshipMapping(withSourceKeyPath: "contact", mapping: Contact.mapping())
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "companies", toKeyPath: "companies", with: Company.mapping()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "providers", toKeyPath: "providers", with: Provider.mapping()))
        return mapping!
    }

    func reload() {
        reload(onSuccess: nil, onError: nil)
    }

    func reload(onSuccess: OnSuccess!, onError: OnError!) {
        ApiService.shared.fetchUser(
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

    func reloadCompanies(onSuccess: OnSuccess!, onError: OnError!) {
        let companyIdsQueryString = companyIds.map({ String($0) }).joined(separator: "|")
        let params: [String: AnyObject] = ["id": companyIdsQueryString as AnyObject]
        ApiService.shared.fetchCompanies(params,
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

    class Annotation: NSObject, MKAnnotation {
        fileprivate var user: User!

        required init(user: User) {
            self.user = user
        }

        @objc var coordinate: CLLocationCoordinate2D {
            return user.coordinate
        }

        @objc var title: String? {
            return nil
        }

        @objc var subtitle: String? {
            return nil
        }
    }
}

// MARK: - Global user

var currentUser: User!
