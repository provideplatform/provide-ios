//
//  ProviderService.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

typealias OnProvidersFetched = (_ providers: [Provider]) -> Void

class ProviderService: NSObject {
    static let shared = ProviderService()

    private var providers = [Provider]()

    private func setProviders(_ providers: [Provider]) {
        self.providers = providers
    }

    func cachedProvider(_ providerId: Int) -> Provider? {
        return providers.first { $0.id == providerId }
    }

    func containsProvider(_ provider: Provider) -> Bool {
        for p in providers where provider.id == p.id {
            return true
        }
        return false
    }

    func appendProvider(_ provider: Provider) {
        providers.append(provider)
    }

    func updateProvider(_ provider: Provider) {
        var newProviders = [Provider]()
        for p in providers {
            if p.id == provider.id {
                newProviders.append(provider)
            } else {
                newProviders.append(p)
            }
        }
        providers = newProviders
    }

    func removeProvider(_ providerId: Int) {
        var newProviders = [Provider]()
        for p in providers where p.id != providerId {
            newProviders.append(p)
        }
        providers = newProviders
    }

    func fetch(  // consider adding a radius param, in miles, configured server-side and fetched after authentication
        _ page: Int = 1,
        rpp: Int = 10,
        available: Bool,
        active: Bool,
        nearbyCoordinate: CLLocationCoordinate2D!,
        onProvidersFetched: @escaping OnProvidersFetched) {

        var params = [
            "page": page,
            "rpp": rpp,
        ] as [String: Any]

        params["available"] = available
        params["active"] = active

        if let nearbyCoordinate = nearbyCoordinate {
            params["nearby"] = "\(nearbyCoordinate.latitude),\(nearbyCoordinate.longitude)"
        }

        ApiService.shared.fetchProviders(params, onSuccess: { [weak self] statusCode, mappingResult in
            if page == 1 {
                self?.providers = [Provider]()
            }
            let fetchedProviders = mappingResult?.array() as! [Provider]
            self?.providers = fetchedProviders
            onProvidersFetched(fetchedProviders)
        }, onError: { error, statusCode, responseString in
            logWarn("Failed to fetch providers; \(statusCode)")
        })
    }
}
