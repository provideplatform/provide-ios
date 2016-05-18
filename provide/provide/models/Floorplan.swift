//
//  Floorplan.swift
//  provide
//
//  Created by Kyle Thomas on 1/18/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Floorplan: Model {

    var id = 0
    var jobId = 0
    var name: String!
    var pdfUrlString: String!
    var thumbnailImageUrlString: String!
    var maxZoomLevel: Int!
    var tilingCompletion = 0.0
    var attachments: [Attachment]!
    var workOrders: [WorkOrder]!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "job_id": "jobId",
            "name": "name",
            "pdf_url": "pdfUrlString",
            "thumbnail_image_url": "thumbnailImageUrlString",
            "max_zoom_level": "maxZoomLevel",
            "tiling_completion": "tilingCompletion",
            ])
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", withMapping: Attachment.mappingWithRepresentations()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "work_orders", toKeyPath: "workOrders", withMapping: Attachment.mappingWithRepresentations()))
        return mapping
    }

    var highResolutionImage: Attachment! {
        if let attachments = attachments {
            for attachment in attachments {
                let tag = "300dpi"
                let isAppropriateResolution = attachment.hasTag(tag)
                let hasThumbnailTag = attachment.hasTag("thumbnail")
                if let mimeType = attachment.mimeType {
                    if mimeType == "image/png" && isAppropriateResolution && !hasThumbnailTag {
                        return attachment
                    }
                } 
            }
        }
        return nil
    }

    var pdf: Attachment! {
        if let attachments = attachments {
            for attachment in attachments {
                if let mimeType = attachment.mimeType {
                    if mimeType == "application/pdf" {
                        return attachment
                    }
                }
            }
        }
        return nil
    }

    var thumbnailImageUrl: NSURL! {
        if let thumbnailImageUrlString = thumbnailImageUrlString {
            return NSURL(string: thumbnailImageUrlString)
        }
        return nil
    }

    var imageUrl: NSURL! {
// FIXME!!!!!!!!!!!!!!!!!!
        return nil
    }

    var scale: Double! {
        return nil
    }

    func save(onSuccess onSuccess: OnSuccess, onError: OnError) {
        var params = toDictionary()
        params.removeValueForKey("id")

        if id > 0 {
            ApiService.sharedService().updateFloorplanWithId(String(id), params: params,
                onSuccess: { statusCode, mappingResult in
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        } else {
            if let pdfUrl = params.removeValueForKey("pdf_url_string") {
                params["pdf_url"] = pdfUrl
            }

            ApiService.sharedService().createFloorplan(params,
                onSuccess: { statusCode, mappingResult in
                    let floorplan = mappingResult.firstObject as! Floorplan
                    self.id = floorplan.id
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        }
    }
}
