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
    var incompleteManifest: NSNumber!
    var currentLegIndex = 0

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromArray([
            "status",
            "id",
            "name",
            ]
        )
        mapping.addRelationshipMappingWithSourceKeyPath("items_loaded", mapping: Product.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("work_orders", mapping: WorkOrder.mapping())
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "Leg", toKeyPath: "legs", withMapping: RouteLeg.mapping()))
        return mapping
    }

    var overviewPolyline: MKPolyline {
        var coords = [CLLocationCoordinate2D]()
        for leg in legs {
            for step in leg.steps {
                let shapes = step.shape
                for shape in shapes {
                    let shapeCoords = shape.splitAtString(",")
                    let latitude = Double(shapeCoords.0)!
                    let longitude = Double(shapeCoords.1)!
                    coords.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                }
            }
        }

        return MKPolyline(coordinates: &coords, count: coords.count)
    }

    var currentLeg: RouteLeg! {
        if legs.count > 0 {
            return legs[currentLegIndex]
        } else {
            return nil
        }
    }

    func canStart() -> Bool {
        return incompleteManifest == false
    }

    var gtinsLoaded: [String] {
        return itemsLoaded.map { $0.gtin }
    }

    var itemsNotLoaded: [Product] {
        var itemsNotLoaded = [Product]()

        for workOrder in workOrders.reverse() {
            for product in workOrder.itemsOrdered {
                itemsNotLoaded.append(product)
            }
        }

        itemsNotLoaded = itemsNotLoaded.filter { self.gtinsLoaded.indexOfObject($0.gtin) == nil }

        return itemsNotLoaded
    }

    var itemsDelivered: [Product] {
        var itemsDelivered = [Product]()
        for workOrder in workOrders.reverse() {
            for product in workOrder.itemsOrdered {
                itemsDelivered.append(product)
            }
        }

        return itemsDelivered
    }

    var itemsOrdered: [Product] {
        var itemsOrdered = [Product]()
        for workOrder in workOrders.reverse() {
            for product in workOrder.itemsOrdered {
                itemsOrdered.append(product)
            }
        }

        return itemsOrdered
    }

    var itemsToLoadCountRemaining: Int {
        return itemsOrdered.count - itemsLoaded.count
    }

    func gtinOrderedCount(gtin: String) -> Int {
        return itemsOrdered.filter { $0.gtin == gtin }.count
    }

    func gtinLoadedCount(gtin: String) -> Int {
        return gtinsLoaded.filter { $0 == gtin }.count
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

    func complete(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "completed"
        ApiService.sharedService().updateRouteWithId(id, params: toDictionary(), onSuccess: onSuccess, onError: onError)
    }

    func load(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "loading"
        ApiService.sharedService().updateRouteWithId(id, params: toDictionary(), onSuccess: onSuccess, onError: onError)
    }

    func start(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "in_progress"
        ApiService.sharedService().updateRouteWithId(id, params: toDictionary(), onSuccess: onSuccess, onError: onError)
    }

    func loadManifestItemByGtin(gtin: String, onSuccess: OnSuccess, onError: OnError) {
        RouteService.loadManifestItemByGtin(gtin, onRoute: self, onSuccess: onSuccess, onError: onError)
    }

    func unloadManifestItemByGtin(gtin: String, onSuccess: OnSuccess, onError: OnError) {
        RouteService.unloadManifestItemByGtin(gtin, onRoute: self, onSuccess: onSuccess, onError: onError)
    }
}
