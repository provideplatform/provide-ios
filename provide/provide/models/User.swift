//
//  User.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

// Global user
var currentUser: User!

@objcMembers
class User: Model {

    var id = 0
    var name: String!
    var email: String!
    var profileImageUrlString: String!
    var contact: Contact!
    var providers: [Provider]!
    var providerIds = [Int]()
    var menuItemsPreference: [[String: String]] = []
    var paymentMethods: [Any]!
    var lastCheckinAt: String!
    var lastCheckinLatitude: Double = 0
    var lastCheckinLongitude: Double = 0
    var lastCheckinHeading: Double = 0

    var annotation: Annotation {
        return Annotation(user: self)
    }

    private var coordinate: CLLocationCoordinate2D? {
        if lastCheckinLatitude != 0 && lastCheckinLongitude != 0 {
            return CLLocationCoordinate2D(latitude: lastCheckinLatitude, longitude: lastCheckinLatitude)
        }
        return nil
    }

    var profileImageUrl: URL? {
        if let profileImageUrlString = profileImageUrlString {
            return URL(string: profileImageUrlString)
        }
        return nil
    }

    var firstName: String? {
        return name?.components(separatedBy: " ").first
    }

    private var lastName: String? {
        guard let name = name else { return nil }
        if name.components(separatedBy: " ").count > 1 {
            return name.components(separatedBy: " ").last!
        } else {
            return nil
        }
    }

    var menuItems: [MenuItem]! {
        if !menuItemsPreference.isEmpty {
            var menuItems = [MenuItem]()
            for menuItemPreference in menuItemsPreference {
                menuItems.append(MenuItem(dict: menuItemPreference))
            }
            return menuItems
        } else {
            var defaultMenuItems = [MenuItem]()
            defaultMenuItems.append(MenuItem(label: "History", storyboard: "Jobs"))
            return defaultMenuItems
        }
    }

    private var hasBeenPromptedToIntegrateQuickbooks: Bool {
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
            "provider_ids": "providerIds",
            "menu_items": "menuItemsPreference",
            "payment_methods": "paymentMethods",
            "last_checkin_at": "lastCheckinAt",
            "last_checkin_latitude": "lastCheckinLatitude",
            "last_checkin_longitude": "lastCheckinLongitude",
            "last_checkin_heading": "lastCheckinHeading",
        ])
        mapping?.addRelationshipMapping(withSourceKeyPath: "contact", mapping: Contact.mapping())
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "providers", toKeyPath: "providers", with: Provider.mapping()))
        return mapping!
    }

    class Annotation: NSObject, MKAnnotation {
        var user: User!

        required init(user: User) {
            self.user = user
        }

        @objc var coordinate: CLLocationCoordinate2D {
            return user.coordinate!
        }

        @objc var title: String? {
            return nil
        }

        @objc var subtitle: String? {
            return nil
        }
    }
}
