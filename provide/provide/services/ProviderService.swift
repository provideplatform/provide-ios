//
//  ProviderService.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnProvidersFetched = (_ providers: [Provider]) -> ()

class ProviderService: NSObject {

    fileprivate var providers = [Provider]()

    fileprivate static let sharedInstance = ProviderService()

    class func sharedService() -> ProviderService {
        return sharedInstance
    }

    func fetch(
        _ page: Int = 1,
        rpp: Int = 10,
        onProvidersFetched: @escaping OnProvidersFetched)
    {
        var params = [
            "page": page,
            "rpp": rpp
        ]

        if let defaultCompanyId = ApiService.sharedService().defaultCompanyId {
            params["company_id"] = defaultCompanyId
        }

        ApiService.sharedService().fetchProviders(params as [String : AnyObject],
            onSuccess: { statusCode, mappingResult in
                let fetchedProviders = mappingResult?.array() as! [Provider]
                self.providers += fetchedProviders

                onProvidersFetched(fetchedProviders)
            },
            onError: { error, statusCode, responseString in
                // TODO
            }
        )
    }
}
