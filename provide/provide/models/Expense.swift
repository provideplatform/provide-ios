//
//  Expense.swift
//  provide
//
//  Created by Kyle Thomas on 12/5/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Expense: Model {

    var id = 0
    var expensableId = 0
    var expensableType: String!
    var amount: Double!
    var desc: String!
    var attachments: [Attachment]!
    var incurredAtString: String!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "expensable_id": "expensableId",
            "expensable_type": "expensableType",
            "amount": "amount",
            "description": "desc",
            "incurred_at": "incurredAtString",
            ])
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", withMapping: Attachment.mapping()))
        return mapping
    }

    var incurredAtDate: NSDate! {
        if let incurredAtString = incurredAtString {
            return NSDate.fromString(incurredAtString)
        }
        return nil
    }

    func attach(image: UIImage, params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) {
        let data = UIImageJPEGRepresentation(image, 1.0)!

        ApiService.sharedService().addAttachment(data, withMimeType: "image/jpg", toExpenseWithId: String(id), forExpensableType: expensableType, withExpensableId: String(expensableId), params: params,
            onSuccess: { statusCode, mappingResult in
                if self.attachments == nil {
                    self.attachments = [Attachment]()
                }
                self.attachments.append(mappingResult.firstObject as! Attachment)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }
}
