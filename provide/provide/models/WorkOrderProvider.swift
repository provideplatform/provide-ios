//
//  WorkOrderProvider.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

class WorkOrderProvider: Model {

    var id = 0
    var providerRating: NSNumber!
    var provider: Provider!
    var checkinCoordinates: NSArray!
    var hourlyRate = -1.0
    var estimatedDuration = -1.0
    var duration = -1.0
    var flatFee = -1.0
    var timedOutAt: String!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id",
            "provider_rating",
            "checkin_coordinates",
            "hourly_rate",
            "estimated_duration",
            "estimated_cost",
            "duration",
            "flat_fee",
            "timed_out_at",
            ]
        )
        mapping?.addRelationshipMapping(withSourceKeyPath: "provider", mapping: Provider.mapping())
        return mapping!
    }

    var isTimedOut: Bool {
        return timedOutAt != nil
    }

    var estimatedCost: Double {
        if hourlyRate > -1.0 && estimatedDuration > -1.0 {
            return hourlyRate * (estimatedDuration / 3600.0)
        }
        return -1.0
    }

    var checkinsPolyline: MKPolyline! {
        var coords = [CLLocationCoordinate2D]()
        if let checkinCoordinates = checkinCoordinates as? [[NSNumber]] {
            for checkinCoordinate in checkinCoordinates {
                let latitude = checkinCoordinate[0].doubleValue
                let longitude = checkinCoordinate[1].doubleValue
                coords.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            }
            return MKPolyline(coordinates: &coords, count: coords.count)
        }

        return nil
    }
}
