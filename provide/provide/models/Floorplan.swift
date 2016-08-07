//
//  Floorplan.swift
//  provide
//
//  Created by Kyle Thomas on 1/18/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

class Floorplan: Model {

    var id = 0
    var jobId = 0
    var name: String!
    var pdfUrlString: String!
    var thumbnailImageUrlString: String!
    var imageUrlString72dpi: String!
    var imageUrlString150dpi: String!
    var imageUrlString300dpi: String!
    var maxZoomLevel = -1
    var tilingCompletion = 0.0
    var tileSize = -1.0
    var tilingXOffset = 0.0
    var tilingYOffset = 0.0
    var tilingBaseUrlString: String!
    var tilingMetadata: NSDictionary!
    var annotations: [Annotation]!
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
            "image_url_72dpi": "imageUrlString72dpi",
            "image_url_150dpi": "imageUrlString150dpi",
            "image_url_300dpi": "imageUrlString300dpi",
            "tiling_base_url": "tilingBaseUrlString",
            "tiling_x_offset": "tilingXOffset",
            "tiling_y_offset": "tilingYOffset",
            "max_zoom_level": "maxZoomLevel",
            "tile_size": "tileSize",
            "tiling_completion": "tilingCompletion",
            "tiling_metadata": "tilingMetadata",
            ])
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", withMapping: Attachment.mappingWithRepresentations()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "work_orders", toKeyPath: "workOrders", withMapping: Attachment.mappingWithRepresentations()))
        return mapping
    }

    var zoomLevels: NSArray! {
        if let tilingMetadata = tilingMetadata {
            if let zoomLevels = tilingMetadata["zoom_levels"] as? NSArray {
                return zoomLevels
            }
        }
        return nil
    }

    var minimumZoomScale: CGFloat {
        if let zoomLevels = zoomLevels {
            if zoomLevels.count > 0 {
                if let minimumZoomLevel = zoomLevels.objectAtIndex(0) as? [String : AnyObject] {
                    if let scale = minimumZoomLevel["scale"] as? CGFloat {
                        return scale
                    }
                }
            }
        }
        return 0.2
    }

    var maximumZoomScale: CGFloat {
        if let zoomLevels = zoomLevels {
            if zoomLevels.count > 0 {
                if let maximumZoomLevel = zoomLevels.objectAtIndex(zoomLevels.count - 1) as? [String : AnyObject] {
                    if let scale = maximumZoomLevel["scale"] as? CGFloat {
                        return scale
                    }
                }
            }
        }
        return 1.0
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

    var tilingBaseUrl: NSURL! {
        if let tilingBaseUrlString = tilingBaseUrlString {
            return NSURL(string: tilingBaseUrlString)
        }
        return nil
    }

    var imageUrl: NSURL! {
        if totalDeviceMemoryInGigabytes() >= 1.0 {
            if let imageUrlString = imageUrlString300dpi {
                return NSURL(imageUrlString)
            }
        } else {
            if isIPad() || isIPhone6Plus() {
                if let imageUrlString = imageUrlString150dpi {
                    return NSURL(imageUrlString)
                }
            } else {
                if let imageUrlString = imageUrlString72dpi {
                    return NSURL(imageUrlString)
                }
            }
        }

        return nil
    }

    var scale: Double! {
        return nil
    }

    func fetchAnnotations(params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) {
        annotations = [Annotation]()

        ApiService.sharedService().fetchAnnotationsForFloorplanWithId(String(id), params: params,
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
