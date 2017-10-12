//
//  Attachment.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

@objcMembers
class Attachment: Model {

    private(set) var id = 0
    private var userId = 0
    private(set) var attachableType: String!
    private(set) var attachableId = 0
    private var desc: String!
    private var key: String!
    private var metadata: [String: Any]!
    private(set) var mimeType: String!
    private var status: String!
    private var tags: [String] = []
    private var displayUrlString: String!
    var urlString: String!
    private var data: Data!
    private var parentAttachmentId = 0
    private var representations = [Attachment]()

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

    private var filename: String! {
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

    private var thumbnailUrl: URL! {
        return (metadata?["thumbnail_url"] as? String).flatMap { URL(string: $0) }
    }

    private var maxZoomLevel: Int! {
        return metadata?["max_zoom_level"] as? Int
    }

    private var tilingBaseUrl: URL! {
        return (metadata?["tiling_base_url"] as? String).flatMap { URL(string: $0) }
    }

    private func hasTag(_ tag: String) -> Bool {
        for t in tags where t == tag {
            return true
        }
        return false
    }

    private func fetch(_ onURLFetched: @escaping OnURLFetched, onError: @escaping OnError) {
        ApiService.shared.fetchURL(url, onURLFetched: { statusCode, response in
            self.data = response
            onURLFetched(statusCode, response)
        }, onError: onError)
    }

    private func updateAttachment(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        ApiService.shared.updateAttachmentWithId(String(id), forAttachableType: attachableType, withAttachableId: String(attachableId), params: params, onSuccess: { statusCode, mappingResult in
            if let metadata = params["metadata"] as? [String: Any] {
                self.metadata = metadata
            }

            onSuccess(statusCode, mappingResult)
        }, onError: onError)
    }
}
