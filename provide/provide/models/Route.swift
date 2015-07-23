//
//  Route.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Route: Model {

    var id = 0
    var name: String!
    var legs = [RouteLeg]()
    var status: String!
    var workOrders = [WorkOrder]()
    var itemsLoaded = [Product]()
    var status: String!
    var legs: [RouteLeg]()
    var workOrders: [WorkOrder]()
    var itemsLoaded: [Product]()
    var incompleteManifest: NSNumber!
    var currentLegIndex = 0
    var dispatcherOriginAssignment: NSDictionary!
    var providerOriginAssignment: ProviderOriginAssignment!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromArray([
            "status",
            "id",
            "name",
            ]
        )
        mapping.addRelationshipMappingWithSourceKeyPath("items_loaded", mapping: Product.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("legs", mapping: RouteLeg.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("provider_origin_assignment", mapping: WorkOrder.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("work_orders", mapping: WorkOrder.mapping())
        return mapping
    }

    var overviewPolyline: MKPolyline {
        var coords = [CLLocationCoordinate2D]()
        for leg in legs {
            for step in leg.steps {
                if let shapes = step.shape {
                    for shape in shapes {
                        let shapeCoords = (shape as! String).splitAtString(",")
                        let latitude = (shapeCoords.0 as NSString).doubleValue
                        let longitude = (shapeCoords.1 as NSString).doubleValue
                        coords.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                    }
                }
            }
        }

        return MKPolyline(coordinates: &coords, count: coords.count)
    }

    var currentLeg: RouteLeg! {
        var leg: RouteLeg!
        if let legs = legs {
            if legs.count > 0 {
                leg = legs[currentLegIndex]
            }
        }
    }

    func canStart() -> Bool {
        return status == "loading" && itemsLoaded.count == itemsOrdered.count
    }

    var completedAllWorkOrders: Bool {
        for workOrder in workOrders {
            if workOrder.status != "completed" {
                return false
            }
        }
        return true
    }

    var disposedOfAllWorkOrders: Bool {
        for workOrder in workOrders {
            if workOrder.status != "completed" && workOrder.status != "canceled" && workOrder.status != "abandoned" {
                return false
            }
        }
        return true
    }

    var gtinsLoaded: [String] {
        var gtinsLoaded = [String]()

        if let products = itemsLoaded {
            for product in products {
                gtinsLoaded.append(product.gtin)
            }
        }

        return gtinsLoaded
    }

    var itemsNotLoaded: [Product] {
        var itemsNotLoaded = [Product]()

        var gtinsAccountedForCount = [String : Int]()
        for gtin in gtinsOrdered {
            gtinsAccountedForCount[gtin] = gtinOrderedCount(gtin) - gtinLoadedCount(gtin)
        }

        if let workOrders = workOrders {
            for workOrder in workOrders.reverse() {
                if let products = workOrder.itemsOrdered {
                    for product in products {
                        let gtin = product.gtin
                        if let remainingToLoad = gtinsAccountedForCount[gtin] {
                            if remainingToLoad > 0 {
                                itemsNotLoaded.append(product)
                                gtinsAccountedForCount[gtin] = remainingToLoad - 1
                            }
                        }
                    }
                }
            }
        }

        return itemsNotLoaded
    }

    var itemsOrdered: [Product] {
        var itemsOrdered = [Product]()
        if let workOrders = workOrders {
            for workOrder in workOrders.reverse() {
                if let products = workOrder.itemsOrdered {
                    for product in products {
                        itemsOrdered.append(product)
                    }
                }
            }
        }

        return itemsOrdered
    }

    var itemsDelivered: [Product] {
        var itemsDelivered = [Product]()
        if let workOrders = workOrders {
            for workOrder in workOrders.reverse() {
                if let products = workOrder.itemsDelivered {
                    for product in products {
                        itemsDelivered.append(product)
                    }
                }
            }
        }

        return itemsDelivered
    }

    var itemsRejected: [Product] {
        var itemsRejected = [Product]()
        if let workOrders = workOrders {
            for workOrder in workOrders.reverse() {
                if let products = workOrder.itemsRejected {
                    for product in products {
                        itemsRejected.append(product)
                    }
                }
            }
        }

        return itemsRejected
    }

    var itemsToLoadCountRemaining: Int {
        return itemsOrdered.count - itemsLoaded.count
    }

    var gtinsOrdered: [String] {
        var gtinsOrdered = [String]()
        for product in itemsOrdered {
            gtinsOrdered.append((product as Product).gtin)
        }
        return gtinsOrdered
    }

    func gtinOrderedCount(gtin: String) -> Int {
        return itemsOrdered.filter { $0.gtin == gtin }.count
    }

    func gtinLoadedCount(gtin: String) -> Int {
        return gtinsLoaded.filter { $0 == gtin }.count
    }

    var itemsToUnloadCountRemaining: Int! {
        return itemsLoaded.count
    }

    func itemForGtin(gtin: String) -> Product? {
        for item in itemsOrdered {
            if item.gtin == gtin {
                return item
            }
        }
        return nil
    }

    func isGtinRequired(gtin: String) -> Bool {
        return gtinOrderedCount(gtin) > gtinLoadedCount(gtin)
    }

    func reload(onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().fetchRouteWithId(id.stringValue, params: ["include_work_orders": "true"],
            onSuccess: { statusCode, mappingResult in
                RouteService.sharedService().updateRoute(mappingResult.firstObject as! Route)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func load(onSuccess: OnSuccess, onError: OnError) {
        status = "loading"
        ApiService.sharedService().updateRouteWithId(id.stringValue, params: toDictionary(),
            onSuccess: { statusCode, mappingResult in
                RouteService.sharedService().updateRoute(self)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func start(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "in_progress"
        ApiService.sharedService().updateRouteWithId(id.stringValue, params: toDictionary(),
            onSuccess: { statusCode, mappingResult in
                RouteService.sharedService().updateRoute(self)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func arrive(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "unloading"
        ApiService.sharedService().updateRouteWithId(id.stringValue, params: toDictionary(),
            onSuccess: { statusCode, mappingResult in
                RouteService.sharedService().updateRoute(self)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func complete(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "pending_completion"
        ApiService.sharedService().updateRouteWithId(id.stringValue, params: toDictionary(),
            onSuccess: { statusCode, mappingResult in
                RouteService.sharedService().updateRoute(self)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func loadManifestItemByGtin(gtin: String!, onSuccess: OnSuccess!, onError: OnError!) {
        RouteService.loadManifestItemByGtin(gtin, onRoute: self, onSuccess: onSuccess, onError: onError)
    }

    func unloadManifestItemByGtin(gtin: String, onSuccess: OnSuccess, onError: OnError) {
        RouteService.unloadManifestItemByGtin(gtin, onRoute: self, onSuccess: onSuccess, onError: onError)
    }
}
