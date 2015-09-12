//
//  ShootingDate.swift
//  startrack
//
//  Created by Kyle Thomas on 9/12/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class ShootingDate: Model {

    var raw: String!

    var date: NSDate {
        let dateFormatter = NSDateFormatter(dateFormat: "yyyy-MM-dd")
        return dateFormatter.dateFromString(raw)!
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addPropertyMapping(RKAttributeMapping(fromKeyPath: nil, toKeyPath: "raw"))
        return mapping
    }
}
