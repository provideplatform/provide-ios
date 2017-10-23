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

    func cachedProvider(_ providerId: Int) -> Provider? {
        return providers.first { $0.id == providerId }
    }

    func containsProvider(_ provider: Provider) -> Bool {
        return providers.contains { $0.id == provider.id }
    }

    func appendProvider(_ provider: Provider) {
        providers.append(provider)
    }

    func updateProvider(_ provider: Provider) {
        if let index = providers.index(where: { $0.id == provider.id }) {
            providers.remove(at: index)
            providers.insert(provider, at: index)
        } else {
            providers.append(provider)
        }
    }

    func removeProvider(_ providerId: Int) {
        providers = providers.filter { $0.id != providerId }
    }

    func fetch(  // consider adding a radius param, in miles, configured server-side and fetched after authentication
        _ page: Int = 1,
        rpp: Int = 10,
        available: Bool,
        active: Bool,
        nearbyCoordinate: CLLocationCoordinate2D!,
        onProvidersFetched: @escaping OnProvidersFetched) {

        var params: [String: Any] = [
            "page": page,
            "rpp": rpp,
        ]

        params["available"] = available
        params["active"] = active

        if let nearbyCoordinate = nearbyCoordinate {
            params["nearby"] = "\(nearbyCoordinate.latitude),\(nearbyCoordinate.longitude)"
        }

        ApiService.shared.fetchProviders(params, onSuccess: { [weak self] statusCode, mappingResult in
            if page == 1 {
                self?.providers = []
            }
            let fetchedProviders = mappingResult?.array() as! [Provider]
            self?.providers = fetchedProviders
            onProvidersFetched(fetchedProviders)
        }, onError: { error, statusCode, responseString in
            logWarn("Failed to fetch providers; \(statusCode)")
        })
    }
}
