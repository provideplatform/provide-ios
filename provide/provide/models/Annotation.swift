//
//  Annotation.swift
//  provide
//
//  Created by Kyle Thomas on 11/14/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Annotation: Model {
    var id = 0
    var workOrderId = 0
    var workOrder: WorkOrder!
    var text: String!
    var polygon: [[CGFloat]]!
    var circle: [[CGFloat]]!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "work_order_id": "workOrderId",
            "text": "text",
            "polygon": "polygon",
            "circle": "circle",
            ])
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "work_order", toKeyPath: "workOrder", withMapping: WorkOrder.mapping()))
        return mapping
    }

    func updatePolygon(attachment: Attachment, onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().updateAnnotationWithId(String(id), forAttachmentWithId: String(attachment.id),
            forAttachableType: attachment.attachableType, withAttachableId: String(attachment.attachableId), params: ["polygon": polygon],
            onSuccess: { statusCode, mappingResult in
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }
}
