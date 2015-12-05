//
//  Expense.swift
//  provide
//
//  Created by Kyle Thomas on 12/5/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Expense: Model {

    var id = 0
    var amount: Double!
    var attachments: [Attachment]!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "amount": "amount",
            ])
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", withMapping: Attachment.mapping()))
        return mapping
    }

}
