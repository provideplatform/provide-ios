//
//  FloorplanService.swift
//  provide
//
//  Created by Kyle Thomas on 1/18/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnFloorplansFetched = (_ floorplans: [Floorplan]) -> ()

class FloorplanService: NSObject {

    fileprivate var floorplans = [Floorplan]()

    fileprivate static let sharedInstance = FloorplanService()

    class func sharedService() -> FloorplanService {
        return sharedInstance
    }

    func floorplanWithId(_ id: Int) -> Floorplan! {
        for floorplan in floorplans {
            if floorplan.id == id {
                return floorplan
            }
        }
        return nil
    }

    func setFloorplans(_ floorplans: [Floorplan]) {
        self.floorplans = floorplans
    }

    func updateFloorplan(_ floorplan: Floorplan) {
        var newFloorplans = [Floorplan]()
        for j in floorplans {
            if j.id == floorplan.id {
                newFloorplans.append(floorplan)
            } else {
                newFloorplans.append(j)
            }
        }
        floorplans = newFloorplans
    }

    func fetch(_ page: Int = 1,
        rpp: Int = 10,
        companyId: Int!,
        customerId: Int! = nil,
        includeCustomer: Bool = false,
        onFloorplansFetched: OnFloorplansFetched!)
    {
        if page == 1 {
            floorplans = [Floorplan]()
        }

        var params: [String: AnyObject] = [
            "page": page as AnyObject,
            "rpp": rpp as AnyObject,
        ]

        if let companyId = companyId {
            params["company_id"] = companyId as AnyObject
        }

        if let customerId = customerId {
            params["customer_id"] = customerId as AnyObject
        }

        if includeCustomer {
            params.updateValue("true" as AnyObject, forKey: "include_customer")
        }

        ApiService.sharedService().fetchFloorplans(params,
            onSuccess: { statusCode, mappingResult in
                let fetchedFloorplans = mappingResult?.array() as! [Floorplan]

                self.floorplans += fetchedFloorplans

                onFloorplansFetched(fetchedFloorplans)
            },
            onError: { error, statusCode, responseString in
                // TODO
            }
        )
    }
}
