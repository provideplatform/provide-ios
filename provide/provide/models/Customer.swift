//
//  Customer.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

class Customer: Model {

    var id = 0
    var companyId = 0
    var name: String!
    var displayName: String!
    var profileImageUrlString: String!
    var contact: Contact!

    var profileImageUrl: URL! {
        if let profileImageUrlString = profileImageUrlString {
            return URL(string: profileImageUrlString)
        }
        return nil
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id": "id",
            "company_id": "companyId",
            "name": "name",
            "display_name": "displayName",
            "profile_image_url": "profileImageUrlString"
        ])
        mapping?.addRelationshipMapping(withSourceKeyPath: "contact", mapping: Contact.mapping())
        return mapping!
    }
}
