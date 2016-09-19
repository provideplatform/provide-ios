//
//  Annotation.swift
//  provide
//
//  Created by Kyle Thomas on 11/14/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

class Annotation: Model {
    var id = 0
    var workOrderId = 0
    var workOrder: WorkOrder!
    var text: String!
    var polygon: [[CGFloat]]!
    var point: [CGFloat]!
    var circle: [[CGFloat]]!
    var metadata: NSDictionary!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id": "id",
            "work_order_id": "workOrderId",
            "text": "text",
            "polygon": "polygon",
            "point": "point",
            "circle": "circle",
            "metadata": "metadata",
            ])
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "work_order", toKeyPath: "workOrder", with: WorkOrder.mapping()))
        return mapping!
    }

//    func save(attachment: Attachment, onSuccess: OnSuccess, onError: OnError) {
//        if id > 0 {
//            var params: [String : AnyObject] = [String : AnyObject]()
//            if let polygon = polygon {
//                params["polygon"] = polygon
//            }
//            if let point = point {
//                params["point"] = point
//            }
//            if let circle = circle {
//                params["circle"] = circle
//            }
//            if let text = text {
//                params["text"] = text
//            }
//            if workOrderId > 0 {
//                params["work_order_id"] = workOrderId
//            }
//            ApiService.sharedService().updateAnnotationWithId(String(id), forAttachmentWithId: String(attachment.id),
//                                                              forAttachableType: attachment.attachableType, withAttachableId: String(attachment.attachableId), params: params,
//                                                              onSuccess: { statusCode, mappingResult in
//                                                                onSuccess(statusCode, mappingResult)
//                },
//                                                              onError: { error, statusCode, responseString in
//                                                                onError(error, statusCode, responseString)
//                }
//            )
//        } else {
//            var params = toDictionary()
//            params.removeValueForKey("id")
//            params.removeValueForKey("work_order")
//
//            ApiService.sharedService().createAnnotationForAttachmentWithId(String(attachment.id),
//                                                                           forAttachableType: attachment.attachableType, withAttachableId: String(attachment.attachableId), params: params,
//                                                                           onSuccess: { statusCode, mappingResult in
//                                                                            let annotation = mappingResult.firstObject as! Annotation
//                                                                            self.id = annotation.id
//                                                                            attachment.annotations.append(self)
//                                                                            
//                                                                            onSuccess(statusCode, mappingResult)
//                },
//                                                                           onError: { error, statusCode, responseString in
//                                                                            onError(error, statusCode, responseString)
//                }
//            )
//        }
//    }

    func save(_ floorplan: Floorplan, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if id > 0 {
            var params: [String : AnyObject] = [String : AnyObject]()
            if let polygon = polygon {
                params["polygon"] = polygon as AnyObject
            }
            if let point = point {
                params["point"] = point as AnyObject
            }
            if let circle = circle {
                params["circle"] = circle as AnyObject
            }
            if let text = text {
                params["text"] = text as AnyObject
            }
            if workOrderId > 0 {
                params["work_order_id"] = workOrderId as AnyObject
            }

            ApiService.sharedService().updateAnnotationWithId(String(id), forFloorplanWithId: String(floorplan.id), params: params,
                onSuccess: { statusCode, mappingResult in
                    onSuccess(statusCode, mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error, statusCode, responseString)
                }
            )
        } else {
            var params = toDictionary()
            params.removeValue(forKey: "id")
            params.removeValue(forKey: "work_order")

            ApiService.sharedService().createAnnotationForFloorplanWithId(String(floorplan.id), params: params,
                onSuccess: { statusCode, mappingResult in
                    let annotation = mappingResult?.firstObject as! Annotation
                    self.id = annotation.id
                    floorplan.annotations?.append(annotation)

                    onSuccess(statusCode, mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error, statusCode, responseString)
                }
            )
        }
    }
}
