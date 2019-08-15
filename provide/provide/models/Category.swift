//
//  Category.swift
//  provide
//
//  Created by Jawwad Ahmad on 10/19/17.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

@objcMembers
class Category: Model {

    var id = 0
    var name = ""
    var abbreviation = ""
    var capacity = 0

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id",
            "name",
            "abbreviation",
            "capacity",
        ])
        return mapping!
    }
}
