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
    var legs: NSArray!
    var status: String!
    var workOrders: NSArray!
    var itemsLoaded: NSArray!
    var incompleteManifest: NSNumber!
    var currentLegIndex: Int!

    override class func mapping() -> RKObjectMapping {
        var mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "status": "status"
        ])
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "Leg", toKeyPath: "legs", withMapping: RouteLeg.mapping()))
        return mapping
    }

    var overviewPolyline: MKPolyline! {
        get {
            var coords = [CLLocationCoordinate2D]()
            for leg in legs {
                for step in (leg as! RouteLeg).steps {
                    if let shapes = (step as! RouteLegStep).shape {
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
    }

    var currentLeg: RouteLeg! {
        get {
            var leg: RouteLeg!
            if let legs = legs {
                if legs.count > 0 {
                    if currentLegIndex == nil {
                        currentLegIndex = 0
                    }

                    leg = legs[currentLegIndex] as! RouteLeg
                }
            }
            return leg
        }
    }

    func canStart() -> Bool {
        return incompleteManifest == false
    }

    var gtinsLoaded: [String] {
        get {
            var gtinsLoaded = [String]()

            if let products = itemsLoaded {
                for product in products {
                    gtinsLoaded.append((product as! Product).gtin)
                }
            }

            return gtinsLoaded
        }
    }

    var itemsNotLoaded: [Product] {
        get {
            var itemsNotLoaded = [Product]()

            if let workOrders = workOrders {
                for workOrder in (workOrders as Array).reverse() {
                    if let products = (workOrder as! WorkOrder).itemsOrdered {
                        for product in products {
                            itemsNotLoaded.append(product as! Product)
                        }
                    }
                }
            }

            if let products = itemsLoaded {
                for productDict in products {
                    itemsNotLoaded = itemsNotLoaded.filter({ self.gtinsLoaded.indexOfObject($0.gtin) == nil })
                }
            }

            return itemsNotLoaded
        }
    }

    var itemsOrdered: [Product] {
        get {
            var itemsOrdered = [Product]()
            if let workOrders = workOrders {
                for workOrder in (workOrders as Array).reverse() {
                    if let products = (workOrder as! WorkOrder).itemsOrdered {
                        for product in products {
                            itemsOrdered.append(product as! Product)
                        }
                    }
                }
            }

            return itemsOrdered
        }
    }

    var itemsToLoadCountRemaining: Int! {
        return itemsOrdered.count - (itemsLoaded != nil ? itemsLoaded.count : 0)
    }

    func gtinOrderedCount(gtin: String!) -> Int {
        var gtinOrderedCount = 0
        for product in itemsOrdered {
            if product.gtin == gtin {
                gtinOrderedCount += 1
            }
        }
        return gtinOrderedCount
    }

    func gtinLoadedCount(gtin: String!) -> Int {
        var gtinLoadedCount = 0
        for gtinLoaded in gtinsLoaded {
            if gtin == gtinLoaded {
                gtinLoadedCount += 1
            }
        }
        return gtinLoadedCount
    }

    func itemForGtin(gtin: String!) -> Product! {
        for item in itemsOrdered {
            if item.gtin == gtin {
                return item
            }
        }
        return nil
    }

    func isGtinRequired(gtin: String!) -> Bool {
        return gtinOrderedCount(gtin) > gtinLoadedCount(gtin)
    }

    func complete(onSuccess: OnSuccess, onError: OnError) {
        status = "completed"
        ApiService.sharedService().updateRouteWithId(id.stringValue, params: toDictionary(), onSuccess: onSuccess, onError: onError)
    }

    func load(onSuccess: OnSuccess, onError: OnError) {
        status = "loading"
        ApiService.sharedService().updateRouteWithId(id.stringValue, params: toDictionary(), onSuccess: onSuccess, onError: onError)
    }

    func start(onSuccess: OnSuccess, onError: OnError) {
        status = "in_progress"
        ApiService.sharedService().updateRouteWithId(id.stringValue, params: toDictionary(), onSuccess: onSuccess, onError: onError)
    }

    func loadManifestItemByGtin(gtin: String!, onSuccess: OnSuccess!, onError: OnError!) {
        RouteService.loadManifestItemByGtin(gtin, onRoute: self, onSuccess: onSuccess, onError: onError)
    }

    func unloadManifestItemByGtin(gtin: String!, onSuccess: OnSuccess!, onError: OnError!) {
        RouteService.unloadManifestItemByGtin(gtin, onRoute: self, onSuccess: onSuccess, onError: onError)
    }

}
