//
//  ProviderService.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//
import KTSwiftExtensions

typealias OnProvidersFetched = (_ providers: [Provider]) -> ()

class ProviderService: NSObject {

    fileprivate var providers = [Provider]()

    fileprivate static let sharedInstance = ProviderService()

    class func sharedService() -> ProviderService {
        return sharedInstance
    }
    
    func fetch(  // consider adding a radius param, in miles, configured server-side and fetched after authentication
        _ page: Int = 1,
        rpp: Int = 10,
        standalone: Bool = false,
        available: Bool = false,
        active: Bool = false,
        publiclyAvailable: Bool = false,
        nearbyCoordinate: CLLocationCoordinate2D!,
        onProvidersFetched: @escaping OnProvidersFetched)
    {
        var params = [
            "page": page,
            "rpp": rpp,
            "standalone": standalone ? "true" : "false",
            "available": available ? "true" : "false",
            "active": active ? "true" : "false",
            "publicly_available": publiclyAvailable ? "true" : "false",
        ] as [String : Any]
        
        if let nearbyCoordinate = nearbyCoordinate {
            params["nearby"] = "\(nearbyCoordinate.latitude),\(nearbyCoordinate.longitude)"
        }

        ApiService.sharedService().fetchProviders(
            params as [String : AnyObject],
            onSuccess: { statusCode, mappingResult in
                let fetchedProviders = mappingResult?.array() as! [Provider]
                self.providers += fetchedProviders
                onProvidersFetched(fetchedProviders)
            },
            onError: { error, statusCode, responseString in
                logWarn("Failed to fetch providers; \(statusCode)")
            }
        )
    }
}
