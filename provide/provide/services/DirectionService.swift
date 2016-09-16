//
//  DirectionService.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnEtaFetched = (_ minutesEta: Int) -> ()
typealias OnDrivingDirectionsFetched = (_ directions: Directions) -> ()

class DirectionService: NSObject {

    fileprivate var canSendDirectionsApiRequest: Bool {
        if let lastRequestDate = lastDirectionsApiRequestDate {
            var sufficientDelta = false
            if let currentLocation = LocationService.sharedService().currentLocation {
                if let lastDirectionsApiRequestCoordinate = lastDirectionsApiRequestCoordinate {
                    let region = CLCircularRegion(center: lastDirectionsApiRequestCoordinate, radius: 10.0, identifier: "sufficientDeltaRegionMonitor")
                    sufficientDelta = !region.contains(currentLocation.coordinate)
                } else {
                    sufficientDelta = true
                }
            }
            if abs(lastRequestDate.timeIntervalSinceNow) >= 1.0 && sufficientDelta {
                return true
            }
        } else {
            return true
        }
        return false
    }

    fileprivate var canSendEtaApiRequest: Bool {
        if let lastRequestDate = lastEtaApiRequestDate {
            if abs(lastRequestDate.timeIntervalSinceNow) >= 1.0 {
                return true
            }
        } else {
            return true
        }
        return false
    }

    fileprivate var lastDirectionsApiRequestCoordinate: CLLocationCoordinate2D!

    fileprivate var lastDirectionsApiRequestDate: Date!
    fileprivate var lastEtaApiRequestDate: Date!

    fileprivate static let sharedInstance = DirectionService()

    class func sharedService() -> DirectionService {
        return sharedInstance
    }

    func fetchDrivingEtaFromCoordinate(_ coordinate: CLLocationCoordinate2D, toCoordinate: CLLocationCoordinate2D, onEtaFetched: @escaping OnEtaFetched) {
        if canSendEtaApiRequest {
            lastEtaApiRequestDate = Date()
            ApiService.sharedService().getDrivingEtaFromCoordinate(coordinate, toCoordinate: toCoordinate,
                onSuccess: { statusCode, mappingResult in
                    if let directions = mappingResult?.firstObject as? Directions {
                        if let minutes = directions.minutes {
                            onEtaFetched(minutes as Int)
                        }
                    }
                },
                onError: { _, statusCode, _ in

                }
            )
        }
    }

    func fetchDrivingDirectionsFromCoordinate(_ coordinate: CLLocationCoordinate2D, toCoordinate: CLLocationCoordinate2D, onDrivingDirectionsFetched: @escaping OnDrivingDirectionsFetched) {
        if canSendDirectionsApiRequest {
            lastDirectionsApiRequestDate = Date()
            lastDirectionsApiRequestCoordinate = coordinate
            ApiService.sharedService().getDrivingDirectionsFromCoordinate(coordinate, toCoordinate: toCoordinate,
                onSuccess: { statusCode, mappingResult in
                    if let directions = mappingResult?.firstObject as? Directions {
                        onDrivingDirectionsFetched(directions)
                    }
                },
                onError: { _, statusCode, _ in

                }
            )
        }
    }
}
