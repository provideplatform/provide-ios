//
//  DirectionService.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnEtaFetched = (minutesEta: Int) -> ()
typealias OnDrivingDirectionsFetched = (directions: Directions) -> ()

class DirectionService: NSObject {

    private var canSendDirectionsApiRequest: Bool {
        if let lastRequestDate = lastDirectionsApiRequestDate {
            var sufficientDelta = false
            if let currentLocation = LocationService.sharedService().currentLocation {
                if let lastDirectionsApiRequestCoordinate = lastDirectionsApiRequestCoordinate {
                    let region = CLCircularRegion(center: lastDirectionsApiRequestCoordinate, radius: 10.0, identifier: "sufficientDeltaRegionMonitor")
                    sufficientDelta = !region.containsCoordinate(currentLocation.coordinate)
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

    private var canSendEtaApiRequest: Bool {
        if let lastRequestDate = lastEtaApiRequestDate {
            if abs(lastRequestDate.timeIntervalSinceNow) >= 1.0 {
                return true
            }
        } else {
            return true
        }
        return false
    }

    private var lastDirectionsApiRequestCoordinate: CLLocationCoordinate2D!

    private var lastDirectionsApiRequestDate: NSDate!
    private var lastEtaApiRequestDate: NSDate!

    private static let sharedInstance = DirectionService()

    class func sharedService() -> DirectionService {
        return sharedInstance
    }

    func fetchDrivingEtaFromCoordinate(coordinate: CLLocationCoordinate2D, toCoordinate: CLLocationCoordinate2D, onEtaFetched: OnEtaFetched) {
        if canSendEtaApiRequest {
            lastEtaApiRequestDate = NSDate()
            ApiService.sharedService().getDrivingEtaFromCoordinate(coordinate, toCoordinate: toCoordinate,
                onSuccess: { statusCode, mappingResult in
                    if let directions = mappingResult.firstObject as? Directions {
                        if let minutes = directions.minutes as? Int {
                            onEtaFetched(minutesEta: minutes)
                        }
                    }
                },
                onError: { _, statusCode, _ in

                }
            )
        }
    }

    func fetchDrivingDirectionsFromCoordinate(coordinate: CLLocationCoordinate2D, toCoordinate: CLLocationCoordinate2D, onDrivingDirectionsFetched: OnDrivingDirectionsFetched) {
        if canSendDirectionsApiRequest {
            lastDirectionsApiRequestDate = NSDate()
            lastDirectionsApiRequestCoordinate = coordinate
            ApiService.sharedService().getDrivingDirectionsFromCoordinate(coordinate, toCoordinate: toCoordinate,
                onSuccess: { statusCode, mappingResult in
                    if let directions = mappingResult.firstObject as? Directions {
                        onDrivingDirectionsFetched(directions: directions)
                    }
                },
                onError: { _, statusCode, _ in

                }
            )
        }
    }

}
