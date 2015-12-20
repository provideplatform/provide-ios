//
//  WorkOrderProvider.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class WorkOrderProvider: Model {

    var id = 0
    var providerRating: NSNumber!
    var provider: Provider!
    var checkinCoordinates: NSArray!
    var hourlyRate = -1.0
    var estimatedDuration = -1.0
    var duration = -1.0

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromArray([
            "id",
            "provider_rating",
            "checkin_coordinates",
            "hourly_rate",
            "estimated_duration",
            "estimated_cost",
            "duration",
            ]
        )
        mapping.addRelationshipMappingWithSourceKeyPath("provider", mapping: Provider.mapping())
        return mapping
    }

    var estimatedCost: Double {
        if hourlyRate > -1.0 && estimatedDuration > -1.0 {
            return hourlyRate * (estimatedDuration / 3600.0)
        }
        return -1.0
    }

    var checkinsPolyline: MKPolyline! {
        var coords = [CLLocationCoordinate2D]()
        if let checkinCoordinates = checkinCoordinates {
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
