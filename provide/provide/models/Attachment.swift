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
    var status: String!
    var displayUrlString: String!
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
            "status": "status",
            "display_url": "displayUrlString",
            "url": "urlString",
        ])
        return mapping
    }

    var url: NSURL! {
        if let status = status {
            if status == "pending" {
                return nil
            }
        }

        if let displayUrlString = displayUrlString {
            return NSURL(string: displayUrlString)
        }
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

    func fetchAnnotations() {
        let params: [String : AnyObject] = ["page": "1", "rpp": "100"]
        ApiService.sharedService().fetchAnnotationsForAttachmentWithId(String(id), forAttachableType: attachableType, withAttachableId: String(attachableId), params: params,
            onSuccess: { statusCode, mappingResult in

            }, onError: { error, statusCode, responseString in

            }
        )
    }
}
