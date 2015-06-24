//
//  Route.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Route: Model {

    var id: NSNumber!
    var name: String!
    var legs: NSArray!
    var status: String!
    var workOrders: NSArray!
    var itemsLoaded: NSArray!
    var incompleteManifest: NSNumber!
    var currentLegIndex = 0

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "status": "status",
            "id": "id",
            "name": "name",
            ])
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "items_loaded", toKeyPath: "itemsLoaded", withMapping: Product.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "work_orders", toKeyPath: "workOrders", withMapping: WorkOrder.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "Leg", toKeyPath: "legs", withMapping: RouteLeg.mapping()))
        return mapping
    }

    var overviewPolyline: MKPolyline {
        var coords = [CLLocationCoordinate2D]()
        for leg in legs {
            for step in (leg as! RouteLeg).steps {
                if let shapes = (step as! RouteLegStep).shape {
                    for shape in shapes {
                        let shapeCoords = (shape as! String).splitAtString(",")
                        let latitude = Double(shapeCoords.0)!
                        let longitude = Double(shapeCoords.1)!
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
                leg = legs[currentLegIndex] as! RouteLeg
            }
        }
        return leg
    }

    func canStart() -> Bool {
        return incompleteManifest == false
    }

    var gtinsLoaded: [String] {
        var gtinsLoaded = [String]()

        if let products = itemsLoaded {
            for product in products {
                gtinsLoaded.append((product as! Product).gtin)
            }
        }

        return gtinsLoaded
    }

    var itemsNotLoaded: [Product] {
        var itemsNotLoaded = [Product]()

        if let workOrders = workOrders {
            for workOrder in Array((workOrders as Array).reverse()) {
                if let products = (workOrder as! WorkOrder).itemsOrdered {
                    for product in products {
                        itemsNotLoaded.append(product as! Product)
                    }
                }
            }
        }

        if itemsLoaded != nil {
            itemsNotLoaded = itemsNotLoaded.filter { self.gtinsLoaded.indexOfObject($0.gtin) == nil }
        }

        return itemsNotLoaded
    }

    var itemsDelivered: [Product] {
        var itemsDelivered = [Product]()
        if let workOrders = workOrders {
            for workOrder in Array((workOrders as Array).reverse()) {
                if let products = (workOrder as! WorkOrder).itemsOrdered {
                    for product in products {
                        itemsDelivered.append(product as! Product)
                    }
                }
            }
        }

        return itemsDelivered
    }

    var itemsOrdered: [Product] {
        var itemsOrdered = [Product]()
        if let workOrders = workOrders {
            for workOrder in Array((workOrders as Array).reverse()) {
                if let products = (workOrder as! WorkOrder).itemsOrdered {
                    for product in products {
                        itemsOrdered.append(product as! Product)
                    }
                }
            }
        }

        return itemsOrdered
    }

    var itemsToLoadCountRemaining: Int {
        return itemsOrdered.count - (itemsLoaded != nil ? itemsLoaded.count : 0)
    }

    func gtinOrderedCount(gtin: String) -> Int {
        var gtinOrderedCount = 0
        for product in itemsOrdered {
            if product.gtin == gtin {
                gtinOrderedCount += 1
            }
        }
        return gtinOrderedCount
    }

    func gtinLoadedCount(gtin: String) -> Int {
        var gtinLoadedCount = 0
        for gtinLoaded in gtinsLoaded {
            if gtin == gtinLoaded {
                gtinLoadedCount += 1
            }
        }
        return gtinLoadedCount
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
        ApiService.sharedService().updateRouteWithId(id.stringValue, params: toDictionary(), onSuccess: onSuccess, onError: onError)
    }

    func load(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "loading"
        ApiService.sharedService().updateRouteWithId(id.stringValue, params: toDictionary(), onSuccess: onSuccess, onError: onError)
    }

    func start(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "in_progress"
        ApiService.sharedService().updateRouteWithId(id.stringValue, params: toDictionary(), onSuccess: onSuccess, onError: onError)
    }

    func loadManifestItemByGtin(gtin: String, onSuccess: OnSuccess, onError: OnError) {
        RouteService.loadManifestItemByGtin(gtin, onRoute: self, onSuccess: onSuccess, onError: onError)
    }

    func unloadManifestItemByGtin(gtin: String, onSuccess: OnSuccess, onError: OnError) {
        RouteService.unloadManifestItemByGtin(gtin, onRoute: self, onSuccess: onSuccess, onError: onError)
    }
}
