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
    var tags: NSArray!
    var displayUrlString: String!
    var urlString: String!
    var data: NSData!
    var representations: [Attachment]!

    var annotations = [Annotation]()

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
            "tags": "tags",
            "display_url": "displayUrlString",
            "url": "urlString",
        ])
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "representations", toKeyPath: "representations", withMapping: Attachment.mapping()))
        return mapping
    }

    var filename: String! {
        if let metadata = metadata {
            if let filename = metadata["filename"] as? String {
                return filename
            }
        }
        return nil
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

    func hasTag(tag: String) -> Bool {
        if let tags = tags {
            for t in tags {
                if t as? String == tag {
                    return true
                }
            }
        }
        return false
    }

    func fetch(onURLFetched: OnURLFetched, onError: OnError) {
        ApiService.sharedService().fetchURL(url,
            onURLFetched: { statusCode, response in
                self.data = response
                onURLFetched(statusCode: statusCode, response: response)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func updateAttachment(params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().updateAttachmentWithId(String(id), forAttachableType: attachableType, withAttachableId: String(attachableId), params: params,
            onSuccess: { [weak self] statusCode, mappingResult in
                if let metadata = params["metadata"] as? [String : AnyObject] {
                    self?.metadata = metadata
                }
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func fetchAnnotations(params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().fetchAnnotationsForAttachmentWithId(String(id), forAttachableType: attachableType, withAttachableId: String(attachableId), params: params,
            onSuccess: { statusCode, mappingResult in
                for annotation in mappingResult.array() as! [Annotation] {
                    self.annotations.append(annotation)
                }
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            }, onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }
}
