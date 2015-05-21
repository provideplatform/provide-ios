//
//  Attachment.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Attachment: Model {

    var id: NSNumber!
    var userId: NSNumber!
    var key: String!
    var publicUrl: String!
    var mimeType: String!
    var fields: NSDictionary!
    var url: String!

    override class func mapping() -> RKObjectMapping {
        var mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "user_id": "userId",
            "key": "key",
            "url": "url",
            "public_url": "publicUrl",
            "mime_type": "mimeType",
            "fields": "fields"
        ])
        return mapping
    }

}
