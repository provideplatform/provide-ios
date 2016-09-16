//
//  Expense.swift
//  provide
//
//  Created by Kyle Thomas on 12/5/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

class Expense: Model {

    var id = 0
    var expensableId = 0
    var expensableType: String!
    var amount = 0.0
    var desc: String!
    var attachments: [Attachment]!
    var incurredAtString: String!
    var receiptImage: UIImage!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id": "id",
            "expensable_id": "expensableId",
            "expensable_type": "expensableType",
            "amount": "amount",
            "description": "desc",
            "incurred_at": "incurredAtString",
            ])
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", with: Attachment.mappingWithRepresentations()))
        return mapping!
    }

    var incurredAtDate: Date! {
        if let incurredAtString = incurredAtString {
            return Date.fromString(incurredAtString)
        }
        return nil
    }

    func attach(_ image: UIImage, params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        let data = UIImageJPEGRepresentation(image, 1.0)!

        ApiService.sharedService().addAttachment(data, withMimeType: "image/jpg", toExpenseWithId: String(id), forExpensableType: expensableType, withExpensableId: String(expensableId), params: params,
            onSuccess: { statusCode, mappingResult in
                if self.attachments == nil {
                    self.attachments = [Attachment]()
                }
                self.attachments.append(mappingResult?.firstObject as! Attachment)
                onSuccess(statusCode, mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error, statusCode, responseString)
            }
        )
    }
}
