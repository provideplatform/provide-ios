//
//  Production.swift
//  startrack
//
//  Created by Kyle Thomas on 9/7/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Production: Model {

    var id = 0
    var name: String!
    var shootingDates = [ShootingDate]()

    var allShootingDates: [NSDate] {
        var dates = [NSDate]()
        for shootingDate in shootingDates {
            dates.append(shootingDate.date)
        }
        return dates
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromArray([
            "id",
            "name",
            ]
        )
        return mapping
    }

    func fetchUniqueShootingDates(onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().fetchUniqueShootingDatesForProductionWithId(String(id),
            onSuccess: { (statusCode, mappingResult) -> () in
                self.shootingDates = mappingResult.array() as! [ShootingDate]

                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }
}
