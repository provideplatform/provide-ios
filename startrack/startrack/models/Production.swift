//
//  Production.swift
//  startrack
//
//  Created by Kyle Thomas on 9/7/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Production: Model {

    var id = 0
    var name: String!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromArray([
            "id",
            "name",
            ]
        )
        return mapping
    }

}
