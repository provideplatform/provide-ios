//
//  Contact.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

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
    var latitude: NSNumber!
    var longitude: NSNumber!
    var desc: String!
    var data: [String: AnyObject]!

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
        if address1 != nil {
            address += address1!
        }
        if address2 != nil {
            address += "\n\(address2)"
        }
        if city != nil {
            address += "\n\(city!), "
        }
        if state != nil {
            address += "\(state!) "
        }
        if zip != nil {
            address += "\(zip!)"
        }
        return address
    }

    func merge(placemark: CLPlacemark) {
        if placemark.thoroughfare != nil && placemark.subThoroughfare != nil {
            address1 = "\(placemark.subThoroughfare!) \(placemark.thoroughfare!)"
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
