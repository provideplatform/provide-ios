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
        onProvidersFetched: OnProvidersFetched)
    {
        var params = [
            "page": page,
            "rpp": rpp
        ]

        if let defaultCompanyId = ApiService.sharedService().defaultCompanyId {
            params["company_id"] = defaultCompanyId
        }

        ApiService.sharedService().fetchProviders(params,
            onSuccess: { statusCode, mappingResult in
                let fetchedProviders = mappingResult.array() as! [Provider]
                self.providers += fetchedProviders

                onProvidersFetched(providers: fetchedProviders)
            },
            onError: { error, statusCode, responseString in
                // TODO
            }
        )
    }
}
