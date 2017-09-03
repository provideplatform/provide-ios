//
//  Provider.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit
import KTSwiftExtensions

class Provider: Model {

    var id = 0
    var companyId = 0
    var userId = 0
    var contact: Contact!
    var profileImageUrlString: String!
    var services: NSSet!
    var available: NSNumber!
    var lastCheckinAt: String!
    var lastCheckinLatitude: NSNumber!
    var lastCheckinLongitude: NSNumber!
    var lastCheckinHeading: NSNumber!

    var name: String? {
        if let name = contact?.name {
            return name
        }
        return nil
    }

    var profileImageUrl: URL? {
        guard let profileImageUrlString = profileImageUrlString else { return nil }
        return URL(string: profileImageUrlString)
    }

    var initialsLabel: UILabel! {
        if let _ = name {
            let initialsLabel = UILabel()
            initialsLabel.text = ""
            if let firstName = self.firstName {
                initialsLabel.text = "\(firstName.substring(to: firstName.startIndex))"
            }
            if let lastName = self.firstName {
                initialsLabel.text = "\(String(describing: initialsLabel.text))\(lastName.substring(to: lastName.startIndex))"
            }
            initialsLabel.sizeToFit()
            return initialsLabel
        }
        return nil
    }
    
    var isAvailable: Bool {
        if let available = available {
            return available.boolValue
        }
        return false
    }
    
    var annotation: Annotation {
        return Annotation(provider: self)
    }

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(self.lastCheckinLatitude.doubleValue,
                                          self.lastCheckinLongitude.doubleValue)
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id": "id",
            "company_id": "companyId",
            "user_id": "userId",
            "name": "name",
            "services": "services",
            "profile_image_url": "profileImageUrlString",
            "available": "available",
            "last_checkin_at": "lastCheckinAt",
            "last_checkin_latitude": "lastCheckinLatitude",
            "last_checkin_longitude": "lastCheckinLongitude",
            "last_checkin_heading": "lastcheckinHeading",
            ])
        mapping?.addRelationshipMapping(withSourceKeyPath: "contact", mapping: Contact.mapping())
        return mapping!
    }

    var firstName: String? {
        if let name = name {
            return name.components(separatedBy: " ").first!
        } else {
            return nil
        }
    }

    var lastName: String? {
        if let name = name {
            if name.components(separatedBy: " ").count > 1 {
                return name.components(separatedBy: " ").last!
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    func reload(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        ApiService.sharedService().fetchProviderWithId(String(id),
            onSuccess: { statusCode, mappingResult in
                onSuccess(statusCode, mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error, statusCode, responseString)
            }
        )
    }

    func save(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var params = toDictionary()
        params.removeValue(forKey: "id")

        if id > 0 {
            ApiService.sharedService().updateProviderWithId(String(id), params: params,
                onSuccess: { statusCode, mappingResult in
                    onSuccess(statusCode, mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error, statusCode, responseString)
                }
            )
        } else {
            params.removeValue(forKey: "user_id")

            ApiService.sharedService().createProvider(params,
                onSuccess: { statusCode, mappingResult in
                    let provider = mappingResult?.firstObject as! Provider
                    self.id = provider.id
                    onSuccess(statusCode, mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error, statusCode, responseString)
                }
            )
        }
    }
    
    func toggleAvailability(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        let val = !isAvailable
        ApiService.sharedService().updateProviderWithId(
            String(id),
            params: ["available": val as AnyObject],
            onSuccess: { [weak self] statusCode, mappingResult in
                logInfo("Provider (id: \(self!.id)) marked \(val ? "available" : "unavailable")")
                self!.available = val ? 1 : 0
                onSuccess(statusCode, mappingResult)
            },
            onError: { [weak self] error, statusCode, responseString in
                logWarn("Failed to update provider (id: \(self!.id)) availability")
                onError(error, statusCode, responseString)
            }
        )
    }
    
    class Annotation: NSObject, MKAnnotation {
        fileprivate var provider: Provider!
        
        required init(provider: Provider) {
            self.provider = provider
        }
        
        @objc var profileImageUrl: URL? {
            return provider.profileImageUrl
        }
        
        @objc var coordinate: CLLocationCoordinate2D {
            return provider.coordinate
        }

        @objc var title: String? {
            return nil
        }
        
        @objc var subtitle: String? {
            return nil
        }
    }
}

var currentProvider: Provider!
