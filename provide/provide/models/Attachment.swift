//
//  Attachment.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Attachment: Model {

    var id = 0
    var userId = 0
    var attachableType: String!
    var attachableId = 0
    var desc: String!
    var fields: NSDictionary!
    var key: String!
    var metadata: NSDictionary!
    var mimeType: String!
    var urlString: String!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "attachable_type": "attachableType",
            "attachable_id": "attachableId",
            "description": "desc",
            "user_id": "userId",
            "fields": "fields",
            "key": "key",
            "metadata": "metadata",
            "mime_type": "mimeType",
            "url": "urlString",
        ])
        return mapping
    }

    var url: NSURL! {
        return NSURL(string: urlString)
    }

    func updateAttachment(params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().updateAttachmentWithId(String(id), forAttachableType: attachableType, withAttachableId: String(attachableId), params: params,
            onSuccess: { statusCode, mappingResult in
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }
}
