//
//  Origin.swift
//  provide
//
//  Created by Kyle Thomas on 6/28/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Origin: Model {

    var id: NSNumber!
    var contact: Contact!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            ])
        mapping.addRelationshipMappingWithSourceKeyPath("contact", mapping: Contact.mapping())
        return mapping
    }

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(contact.latitude.doubleValue,
                                          contact.longitude.doubleValue)
    }

    var regionIdentifier: String {
        return "origin \(id)"
    }

    var regionMonitoringRadius: CLLocationDistance {
        return 50.0
    }
}
