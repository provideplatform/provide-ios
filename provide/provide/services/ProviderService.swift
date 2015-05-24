//
//  ProviderService.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnProvidersFetched = (providers: [Provider]) -> ()

class ProviderService: NSObject {

    private var providers = [Provider]()

    class func sharedService() -> ProviderService {
        struct Static {
            static let instance = ProviderService()
        }
        return Static.instance
    }

    func fetch(page: Int = 1,
               rpp: Int = 10,
               onProvidersFetched: OnProvidersFetched!) {
        let params = [
            "page": page,
            "rpp": rpp
        ]

        ApiService.sharedService().fetchProviders(params,
            onSuccess: { statusCode, mappingResult in
                var fetchedProviders = [Provider]()

                for provider in mappingResult.array() as! [Provider] {
                    self.providers.append(provider)
                    fetchedProviders.append(provider)
                }

                if onProvidersFetched != nil {
                    onProvidersFetched(providers: fetchedProviders)
                }
            }, onError: { error, statusCode, responseString in
                // TODO
            }
        )
    }

}
