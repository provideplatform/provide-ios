//
//  FloorplanService.swift
//  provide
//
//  Created by Kyle Thomas on 1/18/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnFloorplansFetched = (floorplans: [Floorplan]) -> ()

class FloorplanService: NSObject {

    private var floorplans = [Floorplan]()

    private static let sharedInstance = FloorplanService()

    class func sharedService() -> FloorplanService {
        return sharedInstance
    }

    func floorplanWithId(id: Int) -> Floorplan! {
        for floorplan in floorplans {
            if floorplan.id == id {
                return floorplan
            }
        }
        return nil
    }

    func setFloorplans(floorplans: [Floorplan]) {
        self.floorplans = floorplans
    }

    func updateFloorplan(floorplan: Floorplan) {
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

    func fetch(page: Int = 1,
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
            "page": page,
            "rpp": rpp,
        ]

        if let companyId = companyId {
            params["company_id"] = companyId
        }

        if let customerId = customerId {
            params["customer_id"] = customerId
        }

        if includeCustomer {
            params.updateValue("true", forKey: "include_customer")
        }

        ApiService.sharedService().fetchFloorplans(params,
            onSuccess: { statusCode, mappingResult in
                let fetchedFloorplans = mappingResult.array() as! [Floorplan]

                self.floorplans += fetchedFloorplans

                onFloorplansFetched(floorplans: fetchedFloorplans)
            },
            onError: { error, statusCode, responseString in
                // TODO
            }
        )
    }
}
