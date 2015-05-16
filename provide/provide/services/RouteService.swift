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

    required override init() {
        super.init()
    }

    class func sharedService() -> RouteService {
        struct Static {
            static let instance = RouteService()
        }
        return Static.instance
    }

    class func loadManifestItemByGtin(gtin: String, onRoute route: Route!, onSuccess: OnSuccess!, onError: OnError!) {
        if route.isGtinRequired(gtin) {
            var gtinsLoaded = route.gtinsLoaded
            gtinsLoaded.append(gtin)

            ApiService.sharedService().updateRouteWithId(route.id.stringValue, params: ["gtins_loaded": gtinsLoaded], onSuccess: { (statusCode, mappingResult) -> () in
                var itemsLoaded = NSMutableArray(array: route.itemsLoaded)
                itemsLoaded.addObject(route.itemForGtin(gtin))

                route.itemsLoaded = itemsLoaded as [AnyObject]

                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            }, onError: { (error, statusCode, responseString) -> () in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            })
        }
    }

    class func unloadManifestItemByGtin(gtin: String, onRoute route: Route!, onSuccess: OnSuccess!, onError: OnError!) {
        if route.gtinLoadedCount(gtin) > 0 {
            var itemsLoaded = NSMutableArray(array: route.itemsLoaded)
            var i = 0
            for product in route.itemsLoaded {
                if (product as! Product).gtin == gtin {
                    itemsLoaded.removeObjectAtIndex(i)
                    route.itemsLoaded = itemsLoaded as [AnyObject]
                    break
                }
                i++
            }

            ApiService.sharedService().updateRouteWithId(route.id.stringValue, params: ["gtins_loaded": route.gtinsLoaded], onSuccess: { (statusCode, mappingResult) -> () in
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            }, onError: { (error, statusCode, responseString) -> () in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            })
        }
    }

    func fetch(page: Int = 1,
               rpp: Int = 10,
               status: String = "scheduled",
               today: Bool = false,
               nextRouteOnly: Bool = false,
               includeWorkOrders: Bool = true,
               onRoutesFetched: OnRoutesFetched!) {
        let params = NSMutableDictionary(dictionary: [
            "page": (nextRouteOnly ? 1 : page),
            "rpp": (nextRouteOnly ? 1 : rpp),
            "status": status,
            "include_work_orders": (includeWorkOrders == true ? "true" : "false")
        ])

        if today == true {
            let today = NSDate()
            let midnightToday = today.atMidnight.utcString
            let midnightTomorrow = today.atMidnight.dateByAddingTimeInterval(60 * 60 * 24).utcString

            params.setObject("\(midnightToday)..\(midnightTomorrow)", forKey: "date_range")
        }

        ApiService.sharedService().fetchRoutes(params,
            onSuccess: { (statusCode, mappingResult) -> () in
                var fetchedRoutes = [Route]()

                for route in mappingResult.array() as! [Route] {
                    self.routes.append(route)
                    fetchedRoutes.append(route)
                }

                if onRoutesFetched != nil {
                    onRoutesFetched(routes: fetchedRoutes)
                }
            }, onError: { error, statusCode, responseString in
                // TODO
            }
        )
    }

    var nextRoute: Route! {
        get {
            var route: Route!

            var i = 0
            while route == nil && i <= routes.count - 1 {
                let r = routes[i] as Route
                if r.status == "scheduled" {
                    route = r
                }

                i++
            }

            return route
        }
    }

    var inProgressRoute: Route! {
        get {
            var route: Route!

            var i = 0
            while route == nil && i <= routes.count - 1 {
                let r = routes[i] as Route
                if r.status == "in_progress" {
                    route = r
                }

                i++
            }
            
            return route
        }
    }

    var loadingRoute: Route! {
        get {
            var route: Route!

            var i = 0
            while route == nil && i <= routes.count - 1 {
                let r = routes[i] as Route
                if r.status == "loading" {
                    route = r
                }

                i++
            }

            return route
        }
    }

}
