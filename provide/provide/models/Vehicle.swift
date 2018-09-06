//
//  Vehicle.swift
//  carmony
//
//  Created by Kyle Thomas on 9/2/18.
//  Copyright © 2018 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Vehicle: Model {

    public var year: String!
    public var make: String!
    public var model: String!
    public var trim: String!
    public var vin: String!

    public var vehicleImageUrl: String!

    public var latitude: Double!
    public var longitude: Double!

    public var coordinate: CLLocationCoordinate2D? {
        if let latitude = latitude, let longitude = longitude {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        return nil
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "vin",
            "year",
            "make",
            "model",
            "trim",
            "latitude",
            "longitude",
            "vehicle_image_url",
            ])
        return mapping!
    }

    override var description: String {
        if year == nil || make == nil || model == nil {
            return "<invalid YMMT>"
        }
        var ymmt = "\(year!) \(make!) \(model!)"
        if let trim = trim {
            ymmt = "\(ymmt) \(trim)"
        }
        return ymmt
    }

}
