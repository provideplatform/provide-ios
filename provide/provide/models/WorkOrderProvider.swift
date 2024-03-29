//
//  WorkOrderProvider.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

@objcMembers
class WorkOrderProvider: Model {

    var id = 0
    var rating = 0.0
    var provider: Provider!
    var checkinCoordinates: [[Double]] = []
    var hourlyRate = -1.0
    var estimatedCost = -1.0
    var estimatedDuration = -1.0
    var duration = -1.0
    var flatFee = -1.0
    var timedOutAt: String!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "checkin_coordinates",
            "duration",
            "estimated_cost",
            "estimated_duration",
            "flat_fee",
            "hourly_rate",
            "id",
            "rating",
            "timed_out_at",
        ])
        mapping?.addRelationshipMapping(withSourceKeyPath: "provider", mapping: Provider.mapping())
        return mapping!
    }

    var isTimedOut: Bool {
        return timedOutAt != nil
    }

    var checkinsPolyline: MKPolyline? {
        var coords = [CLLocationCoordinate2D]()
        if !checkinCoordinates.isEmpty {
            for checkinCoordinate in checkinCoordinates {
                coords.append(CLLocationCoordinate2D(latitude: checkinCoordinate[0], longitude: checkinCoordinate[1]))
            }
            return MKPolyline(coordinates: &coords, count: coords.count)
        }

        return nil
    }
}
