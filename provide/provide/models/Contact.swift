//
//  Contact.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

@objcMembers
class Contact: Model {

    var id = 0
    var name: String!
    var address1: String!
    var address2: String!
    var city: String!
    var state: String!
    var zip: String!
    var email: String!
    var phone: String!
    var fax: String!
    var mobile: String!
    var timeZoneId: String!
    var latitude: Double = 0
    var longitude: Double = 0
    var desc: String!
    var data: [String: Any]!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id",
            "name",
            "address1",
            "address2",
            "city",
            "state",
            "zip",
            "email",
            "phone",
            "fax",
            "mobile",
            "time_zone_id",
            "latitude",
            "longitude",
            "data",
        ])
        mapping?.addAttributeMappings(from: [
            "description": "desc",
        ])
        return mapping!
    }

    var address: String {
        var address = ""
        if let address1 = address1 {
            address += address1
        }
        if let address2 = address2 {
            address += "\n\(address2)"
        }
        if let city = city {
            address += "\n\(city), "
        }
        if let state = state {
            address += "\(state) "
        }
        if let zip = zip {
            address += "\(zip)"
        }
        return address
    }

    func merge(placemark: CLPlacemark) {
        if let subThoroughfare = placemark.subThoroughfare, let thoroughfare = placemark.thoroughfare {
            address1 = "\(subThoroughfare) \(thoroughfare)"
        }

        if let locality = placemark.locality {
            city = locality
        }

        if let administrativeArea = placemark.administrativeArea {
            state = administrativeArea
        }

        if let postalCode = placemark.postalCode {
            zip = postalCode
        }
    }
}
