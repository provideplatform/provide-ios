//
//  Annotation.swift
//  provide
//
//  Created by Kyle Thomas on 11/14/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Annotation: Model {

    var id = 0
    var text: String!
    var polygon: [[CGFloat]]!
    var circle: [[CGFloat]]!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "text": "text",
            "polygon": "polygon",
            "circle": "circle",
            ])
        return mapping
    }
}
