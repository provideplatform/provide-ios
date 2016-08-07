//
//  Category.swift
//  provide
//
//  Created by Kyle Thomas on 3/19/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

class Category: Model {

    var id = 0
    var name: String!
    var abbreviation: String!
    var iconImageUrlString: String!

    var iconImageUrl: NSURL! {
        if let iconImageUrlString = iconImageUrlString {
            return NSURL(iconImageUrlString)
        }
        return nil
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "name": "name",
            "abbreviation": "abbreviation",
            "icon_image_url": "iconImageUrlString",
            ])
        mapping.addRelationshipMappingWithSourceKeyPath("user", mapping: User.mapping())
        return mapping
    }
}
