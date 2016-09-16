//
//  ProviderOriginAssignment.swift
//  provide
//
//  Created by Kyle Thomas on 6/28/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

class ProviderOriginAssignment: Model {

    var id: NSNumber!
    var origin: Origin!
    var provider: Provider!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id": "id",
            ])
        mapping?.addRelationshipMapping(withSourceKeyPath: "provider", mapping: Provider.mapping())
        mapping?.addRelationshipMapping(withSourceKeyPath: "origin", mapping: Origin.mapping())
        return mapping!
    }
}
