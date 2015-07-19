//
//  RouteService.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnRoutesFetched = (routes: [Route]) -> ()
typealias OnWorkOrderDrivingDirectionsFetched = (workOrder: WorkOrder, directions: Directions) -> ()

class RouteService: NSObject {

    private var routes = [Route]()

    private static let sharedInstance = RouteService()

    class func sharedService() -> RouteService {
        return sharedInstance
    }

    class func loadManifestItemByGtin(gtin: String, onRoute route: Route, onSuccess: OnSuccess, onError: OnError) {
        if route.isGtinRequired(gtin) {
            var gtinsLoaded = route.gtinsLoaded
            gtinsLoaded.append(gtin)

            ApiService.sharedService().updateRouteWithId(route.id, params: ["gtins_loaded": gtinsLoaded],
                onSuccess: { statusCode, mappingResult in
                    route.itemsLoaded.append(route.itemForGtin(gtin)!)
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: onError
            )
        }
    }

    class func unloadManifestItemByGtin(gtin: String, onRoute route: Route, onSuccess: OnSuccess, onError: OnError) {
        if route.gtinLoadedCount(gtin) > 0 {
            for (i, product) in route.itemsLoaded.enumerate() {
                var itemsLoaded = [Product](route.itemsLoaded)
                if product.gtin == gtin {
                    itemsLoaded.removeAtIndex(i)
                    route.itemsLoaded = itemsLoaded
                    break
                }
            }

            ApiService.sharedService().updateRouteWithId(route.id, params: ["gtins_loaded": route.gtinsLoaded], onSuccess: onSuccess, onError: onError)
        }
    }

    func fetch(page: Int = 1,
        rpp: Int = 10,
        status: String = "scheduled",
        today: Bool = false,
        nextRouteOnly: Bool = false,
        includeWorkOrders: Bool = true,
        onRoutesFetched: OnRoutesFetched)
    {
        var params: [String: AnyObject] = [
            "page": (nextRouteOnly ? 1 : page),
            "rpp": (nextRouteOnly ? 1 : rpp),
            "status": status,
            "include_work_orders": includeWorkOrders ? "true" : "false"
        ]

        if today {
            let today = NSDate()
            let midnightToday = today.atMidnight.utcString
            let midnightTomorrow = today.atMidnight.dateByAddingTimeInterval(60 * 60 * 24).utcString

            params["date_range"] = "\(midnightToday)..\(midnightTomorrow)"
        }

        ApiService.sharedService().fetchRoutes(params,
            onSuccess: { statusCode, mappingResult in
                let fetchedRoutes = mappingResult.array() as! [Route]
                self.routes += fetchedRoutes

                onRoutesFetched(routes: fetchedRoutes)
            },
            onError: { error, statusCode, responseString in
                // TODO
            }
        )
    }

    func fetchInProgressRouteOriginDrivingDirectionsFromCoordinate(coordinate: CLLocationCoordinate2D, onDrivingDirectionsFetched: OnDrivingDirectionsFetched) {
        if let route = inProgressRoute {
            if let providerOriginAssignment = route.providerOriginAssignment {
                if let origin = providerOriginAssignment.origin {
                    DirectionService.sharedService().fetchDrivingDirectionsFromCoordinate(coordinate, toCoordinate: origin.coordinate) { directions in
                        onDrivingDirectionsFetched(directions: directions)
                    }
                }
            }
        }
    }

    func setInProgressRouteOriginRegionMonitoringCallbacks(onDidEnterRegion: VoidBlock, onDidExitRegion: VoidBlock) {
        if let route = inProgressRoute {
            if let providerOriginAssignment = route.providerOriginAssignment {
                if let origin = providerOriginAssignment.origin {
                    LocationService.sharedService().unregisterRegionMonitor(origin.regionIdentifier)

                    let overlay = MKCircle(centerCoordinate: origin.coordinate, radius: origin.regionMonitoringRadius)
                    LocationService.sharedService().monitorRegionWithCircularOverlay(overlay,
                        identifier: origin.regionIdentifier,
                        onDidEnterRegion: onDidEnterRegion,
                        onDidExitRegion: onDidExitRegion)
                }
            }
        }
    }

    var currentRoute: Route! {
        if let route = loadingRoute {
            return route
        } else if let route = inProgressRoute {
            return route
        } else if let route = unloadingRoute {
            return route
        }
        return nil
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

    var unloadingRoute: Route! {
        return routes.findFirst { $0.status == "unloading" }
    }
}
