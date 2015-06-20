//
//  RouteService.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnRoutesFetched = (routes: [Route]) -> ()

class RouteService: NSObject {

    private var routes = [Route]()

    private static let sharedInstance = RouteService()

    class func sharedService() -> RouteService {
        return sharedInstance
    }

    class func loadManifestItemByGtin(gtin: String, onRoute route: Route!, onSuccess: OnSuccess!, onError: OnError!) {
        if route.isGtinRequired(gtin) {
            var gtinsLoaded = route.gtinsLoaded
            gtinsLoaded.append(gtin)

            ApiService.sharedService().updateRouteWithId(route.id.stringValue, params: ["gtins_loaded": gtinsLoaded],
                onSuccess: { statusCode, mappingResult in
                    let itemsLoaded = NSMutableArray(array: route.itemsLoaded)
                    itemsLoaded.addObject(route.itemForGtin(gtin))

                    route.itemsLoaded = itemsLoaded as [AnyObject]

                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: onError
            )
        }
    }

    class func unloadManifestItemByGtin(gtin: String, onRoute route: Route!, onSuccess: OnSuccess!, onError: OnError!) {
        if route.gtinLoadedCount(gtin) > 0 {
            for (i, product) in enumerate(route.itemsLoaded) {
            let itemsLoaded = NSMutableArray(array: route.itemsLoaded)
                if (product as! Product).gtin == gtin {
                    itemsLoaded.removeObjectAtIndex(i)
                    route.itemsLoaded = itemsLoaded as [AnyObject]
                    break
                }
            }

            ApiService.sharedService().updateRouteWithId(route.id.stringValue, params: ["gtins_loaded": route.gtinsLoaded], onSuccess: onSuccess, onError: onError)
        }
    }

    func fetch(page: Int = 1,
        rpp: Int = 10,
        status: String = "scheduled",
        today: Bool = false,
        nextRouteOnly: Bool = false,
        includeWorkOrders: Bool = true,
        onRoutesFetched: OnRoutesFetched!)
    {
        let params = NSMutableDictionary(dictionary: [
            "page": (nextRouteOnly ? 1 : page),
            "rpp": (nextRouteOnly ? 1 : rpp),
            "status": status,
            "include_work_orders": (includeWorkOrders ? "true" : "false")
            ])

        if today {
            let today = NSDate()
            let midnightToday = today.atMidnight.utcString
            let midnightTomorrow = today.atMidnight.dateByAddingTimeInterval(60 * 60 * 24).utcString

            params.setObject("\(midnightToday)..\(midnightTomorrow)", forKey: "date_range")
        }

        ApiService.sharedService().fetchRoutes(params,
            onSuccess: { statusCode, mappingResult in
                let fetchedRoutes = mappingResult.array() as! [Route]
                self.routes += fetchedRoutes

                if onRoutesFetched != nil {
                    onRoutesFetched(routes: fetchedRoutes)
                }
            },
            onError: { error, statusCode, responseString in
                // TODO
            }
        )
    }

    var nextRoute: Route! {
        return routes.findFirst { $0.status == "scheduled" }
    }

    var inProgressRoute: Route! {
        return routes.findFirst { $0.status == "in_progress" }
    }

    var loadingRoute: Route! {
        return routes.findFirst { $0.status == "loading" }
    }
}
