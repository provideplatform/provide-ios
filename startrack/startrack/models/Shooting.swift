//
//  Shooting.swift
//  startrack
//
//  Created by Kyle Thomas on 9/12/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Shooting: Model {

    var id = 0
    var dateString: String!

    var location: Customer!

    var date: NSDate {
        return NSDate.fromString(dateString)
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromArray([
            "id",
            ]
        )
        mapping.addAttributeMappingsFromDictionary([
            "date": "dateString"
            ]
        )
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "location", toKeyPath: "location", withMapping: Customer.mapping()))
        return mapping
    }
}
