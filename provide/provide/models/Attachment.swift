//
//  Attachment.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

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
    var data: Data!
    var parentAttachmentId = 0
    var representations = [Attachment]()

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id": "id",
            "attachable_type": "attachableType",
            "attachable_id": "attachableId",
            "description": "desc",
            "user_id": "userId",
            "fields": "fields",
            "key": "key",
            "metadata": "metadata",
            "mime_type": "mimeType",
            "parent_attachment_id": "parentAttachmentId",
            "status": "status",
            "tags": "tags",
            "display_url": "displayUrlString",
            "url": "urlString",
        ])
        return mapping!
    }

    class func mappingWithRepresentations(_ levels: Int = 1) -> RKObjectMapping {
        // var i = 0
        let mapping = Attachment.mapping()
        // while i < levels - 1 {
        //     i += 1
        //
        //     let nestedMapping = Attachment.mapping()
        //     nestedMapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "representations", toKeyPath: "representations", withMapping: mappingWithRepresentations(levels - i)))
        // }
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "representations", toKeyPath: "representations", with: Attachment.mapping()))
        return mapping
    }

    var filename: String! {
        return metadata?["filename"] as? String
    }

    var url: URL! {
        if let status = status, status == "pending" {
            return nil
        } else if let displayUrlString = displayUrlString {
            return URL(string: displayUrlString)
        } else if let urlString = urlString {
            return URL(string: urlString)
        } else {
            return nil
        }
    }

    var thumbnailUrl: URL! {
        if let metadata = metadata, let thumbnailUrlString = metadata["thumbnail_url"] as? String {
            return URL(string: thumbnailUrlString)
        } else {
            return nil
        }
    }

    var maxZoomLevel: Int! {
        if let metadata = metadata, let maxZoomLevel = metadata["max_zoom_level"] as? Int {
            return maxZoomLevel
        } else {
            return nil
        }
    }

    var tilingBaseUrl: URL! {
        if let metadata = metadata, let tilingBaseUrlString = metadata["tiling_base_url"] as? String {
            return URL(string: tilingBaseUrlString)
        } else {
            return nil
        }
    }

    func hasTag(_ tag: String) -> Bool {
        if let tags = tags {
            for t in tags where t as? String == tag {
                return true
            }
        }
        return false
    }

    func fetch(_ onURLFetched: @escaping OnURLFetched, onError: @escaping OnError) {
        ApiService.shared.fetchURL(url, onURLFetched: { statusCode, response in
            self.data = response
            onURLFetched(statusCode, response)
        }, onError: onError)
    }

    func updateAttachment(_ params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        ApiService.shared.updateAttachmentWithId(String(id), forAttachableType: attachableType, withAttachableId: String(attachableId), params: params, onSuccess: { [weak self] statusCode, mappingResult in
            if let metadata = params["metadata"] as? [String : AnyObject] {
                self?.metadata = metadata as NSDictionary
            }

            onSuccess(statusCode, mappingResult)
        }, onError: onError)
    }
}
