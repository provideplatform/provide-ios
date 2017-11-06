//
//  Provider.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

var currentProvider: Provider!

@objcMembers
class Provider: Model {

    var id = 0
    var userId = 0
    var categoryId = 0
    var contact: Contact!
    var profileImageUrlString: String!
    var available: Bool = false
    var lastCheckinAt: String!
    var lastCheckinLatitude: Double = 0
    var lastCheckinLongitude: Double = 0
    var lastCheckinHeading: Double = 0

    var name: String? {
        return contact?.name
    }

    var profileImageUrl: URL? {
        guard let profileImageUrlString = profileImageUrlString else { return nil }
        return URL(string: profileImageUrlString)
    }

    private var initialsLabel: UILabel? {
        if name != nil {
            let initialsLabel = UILabel()
            initialsLabel.text = ""
            if let firstName = firstName {
                initialsLabel.text = String(firstName[...firstName.startIndex])
            }
            if let lastName = firstName {
                initialsLabel.text = "\(String(describing: initialsLabel.text!))\(String(lastName[...lastName.startIndex]))"
            }
            initialsLabel.sizeToFit()
            return initialsLabel
        }
        return nil
    }

    var isAvailable: Bool {
        return available
    }

    var annotation: Annotation {
        return Annotation(provider: self)
    }

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lastCheckinLatitude, longitude: lastCheckinLongitude)
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id": "id",
            "user_id": "userId",
            "category_id": "categoryId",
            "name": "name",
            "profile_image_url": "profileImageUrlString",
            "available": "available",
            "last_checkin_at": "lastCheckinAt",
            "last_checkin_latitude": "lastCheckinLatitude",
            "last_checkin_longitude": "lastCheckinLongitude",
            "last_checkin_heading": "lastCheckinHeading",
        ])
        mapping?.addRelationshipMapping(withSourceKeyPath: "contact", mapping: Contact.mapping())
        return mapping!
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

    private func reload(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        ApiService.shared.fetchProviderWithId(String(id), onSuccess: { statusCode, mappingResult in
            onSuccess(statusCode, mappingResult)
        }, onError: onError)
    }

    private func save(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var params = toDictionary()
        params.removeValue(forKey: "id")

        if id > 0 {
            ApiService.shared.updateProviderWithId(String(id), params: params, onSuccess: onSuccess, onError: onError)
        } else {
            params.removeValue(forKey: "user_id")

            ApiService.shared.createProvider(params, onSuccess: { statusCode, mappingResult in
                let provider = mappingResult?.firstObject as! Provider
                self.id = provider.id
                onSuccess(statusCode, mappingResult)
            }, onError: onError)
        }
    }

    func toggleAvailability(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        let val = !isAvailable
        ApiService.shared.updateProviderWithId(String(id), params: ["available": val], onSuccess: { statusCode, mappingResult in
            logInfo("Provider (id: \(self.id)) marked \(val ? "available" : "unavailable")")
            self.available = val
            onSuccess(statusCode, mappingResult)
        }, onError: { [weak self] error, statusCode, responseString in
            logWarn("Failed to update provider (id: \(self!.id)) availability")
            onError(error, statusCode, responseString)
        })
    }

    class Annotation: NSObject, MKAnnotation {
        @objc dynamic var coordinate: CLLocationCoordinate2D
        @objc dynamic var title: String?
        @objc dynamic var subtitle: String?

        @objc var icon: UIImage? {
            if provider.categoryId > 0 {
                return CategoryService.shared.iconForCategoryId(provider.categoryId)
            }
            return #imageLiteral(resourceName: "prvdX")
        }

        @objc var profileImageUrl: URL? {
            return provider.profileImageUrl
        }

        var provider: Provider!

        func matches(_ otherProvider: Provider) -> Bool {
            return otherProvider.id == provider.id
        }

        func matchesCategory(_ category: Category) -> Bool {
            return category.id == provider.categoryId
        }

        required init(provider: Provider) {
            self.provider = provider
            self.coordinate = provider.coordinate
        }
    }
}
