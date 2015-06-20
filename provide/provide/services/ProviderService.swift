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

    private static let sharedInstance = ProviderService()

    class func sharedService() -> ProviderService {
        return sharedInstance
    }

    func fetch(
        page: Int = 1,
        rpp: Int = 10,
        onProvidersFetched: OnProvidersFetched!)
    {
        let params = [
            "page": page,
            "rpp": rpp
        ]

        ApiService.sharedService().fetchProviders(params,
            onSuccess: { statusCode, mappingResult in
                let fetchedProviders = mappingResult.array() as! [Provider]
                self.providers += fetchedProviders

                if onProvidersFetched != nil {
                    onProvidersFetched(providers: fetchedProviders)
                }
            },
            onError: { error, statusCode, responseString in
                // TODO
            }
        )
    }
}
