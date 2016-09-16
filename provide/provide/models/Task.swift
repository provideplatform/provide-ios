//
//  Task.swift
//  provide
//
//  Created by Kyle Thomas on 1/11/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

class Task: Model {

    var id = 0
    var companyId = 0
    var userId = 0
    var providerId = 0
    var jobId = 0
    var workOrderId = 0
    var name: String!
    var desc: String!
    var status: String!
    var dueAtString: String!
    var completedAtString: String!

    var completedAt: Date! {
        if let completedAtString = completedAtString {
            return Date.fromString(completedAtString)
        }
        return nil
    }

    var dueAt: Date! {
        if let dueAtString = dueAtString {
            return Date.fromString(dueAtString)
        }
        return nil
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id": "id",
            "company_id": "companyId",
            "user_id": "userId",
            "provider_id": "providerId",
            "job_id": "jobId",
            "work_order_id": "workOrderId",
            "name": "name",
            "description": "desc",
            "due_at": "dueAtString",
            "completed_at": "completedAtString",
            "declined_at": "declinedAtString",
            "status": "status",
            ])
        return mapping!
    }

    override func toDictionary(_ snakeKeys: Bool = true, includeNils: Bool = false, ignoreKeys: [String] = [String]()) -> [String : AnyObject] {
        var params = super.toDictionary()

        if providerId == 0 {
            params.removeValue(forKey: "provider_id")
        }

        if jobId == 0 {
            params.removeValue(forKey: "job_id")
        }

        if workOrderId == 0 {
            params.removeValue(forKey: "work_order_id")
        }

        return params
    }

    func save(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        let params = self.toDictionary()

        if id > 0 {
            ApiService.sharedService().updateTaskWithId(String(id), params: params,
                onSuccess: { statusCode, mappingResult in
                    onSuccess(statusCode, mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error, statusCode, responseString)
                }
            )
        } else {
            ApiService.sharedService().createTask(params,
                onSuccess: { statusCode, mappingResult in
                    onSuccess(statusCode, mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error, statusCode, responseString)
                }
            )
        }
    }
}
