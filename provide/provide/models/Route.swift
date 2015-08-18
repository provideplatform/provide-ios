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
    var status: String!
    var scheduledStartAt: String!
    var scheduledEndAt: String!
    var startedAt: String!
    var endedAt: String!
    var loadingStartedAt: String!
    var loadingEndedAt: String!
    var unloadingStartedAt: String!
    var unloadingEndedAt: String!
    var legs = [RouteLeg]()
    var workOrders = [WorkOrder]()
    var itemsLoaded = [Product]()
    var checkinCoordinates: NSArray!
    var incompleteManifest: NSNumber!
    var currentLegIndex = 0
    var dispatcherOriginAssignment: NSDictionary!
    var providerOriginAssignment: ProviderOriginAssignment!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "status": "status",
            "id": "id",
            "name": "name",
            "scheduled_started_at": "scheduledStartAt",
            "scheduled_end_at": "scheduledEndAt",
            "started_at": "startedAt",
            "ended_at": "endedAt",
            "loading_started_at": "loadingStartedAt",
            "loading_ended_at": "loadingEndedAt",
            "unloading_started_at": "unloadingStartedAt",
            "unloading_ended_at": "unloadingEndedAt",
            "checkin_coordinates": "checkinCoordinates",
            ])

        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "provider_origin_assignment", toKeyPath: "providerOriginAssignment", withMapping: ProviderOriginAssignment.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "items_loaded", toKeyPath: "itemsLoaded", withMapping: Product.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "work_orders", toKeyPath: "workOrders", withMapping: WorkOrder.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "Leg", toKeyPath: "legs", withMapping: RouteLeg.mapping()))
        return mapping
    }

    var humanReadableScheduledStartAtTimestamp: String! {
        if let scheduledStartAtDate = scheduledStartAtDate {
            return "\(scheduledStartAtDate.dayOfWeek), \(scheduledStartAtDate.monthName) \(scheduledStartAtDate.dayOfMonth) @ \(scheduledStartAtDate.timeString!)"
        }
        return nil
    }

    var humanReadableScheduledEndAtTimestamp: String! {
        if let scheduledEndAtDate = scheduledEndAtDate {
            return "\(scheduledEndAtDate.dayOfWeek), \(scheduledEndAtDate.monthName) \(scheduledEndAtDate.dayOfMonth) @ \(scheduledEndAtDate.timeString!)"
        }
        return nil
    }

    var humanReadableStartedAtTimestamp: String! {
        if let startedAtDate = startedAtDate {
            return "\(startedAtDate.dayOfWeek), \(startedAtDate.monthName) \(startedAtDate.dayOfMonth) @ \(startedAtDate.timeString!)"
        }
        return nil
    }

    var humanReadableEndedAtTimestamp: String! {
        if let endedAtDate = endedAtDate {
            return "\(endedAtDate.dayOfWeek), \(endedAtDate.monthName) \(endedAtDate.dayOfMonth) @ \(endedAtDate.timeString!)"
        }
        return nil
    }

    var humanReadableLoadingStartedAtTimestamp: String! {
        if let loadingStartedAtDate = loadingStartedAtDate {
            return "\(loadingStartedAtDate.dayOfWeek), \(loadingStartedAtDate.monthName) \(loadingStartedAtDate.dayOfMonth) @ \(loadingStartedAtDate.timeString!)"
        }
        return nil
    }

    var humanReadableUnloadingStartedAtTimestamp: String! {
        if let unloadingStartedAtDate = unloadingStartedAtDate {
            return "\(unloadingStartedAtDate.dayOfWeek), \(unloadingStartedAtDate.monthName) \(unloadingStartedAtDate.dayOfMonth) @ \(unloadingStartedAtDate.timeString!)"
        }
        return nil
    }

    func updateWorkOrder(workOrder: WorkOrder) {
        var newWorkOrders = [WorkOrder]()
        for wo in workOrders {
            if wo.id == workOrder.id {
                newWorkOrders.append(workOrder)
            } else {
                newWorkOrders.append(wo)
            }
        }
        workOrders = newWorkOrders
    }

    var checkinsPolyline: MKPolyline! {
        var coords = [CLLocationCoordinate2D]()
        if let checkinCoordinates = checkinCoordinates {
            for checkinCoordinate in checkinCoordinates {
                let latitude = checkinCoordinate[0].doubleValue
                let longitude = checkinCoordinate[1].doubleValue
                coords.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            }
            return MKPolyline(coordinates: &coords, count: coords.count)
        }

        return nil
    }

    var overviewPolyline: MKPolyline {
        var coords = [CLLocationCoordinate2D]()
        for leg in legs {
            for step in leg.steps {
                if let shapes = step.shape {
                    for shape in shapes {
                        let shapeCoords = shape.splitAtString(",")
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
        if legs.count > 0 {
            leg = legs[currentLegIndex]
        }
        return leg
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

        for product in itemsLoaded {
            gtinsLoaded.append(product.gtin)
        }

        return gtinsLoaded
    }

    var itemsNotLoaded: [Product] {
        var itemsNotLoaded = [Product]()

        var gtinsAccountedForCount = [String : Int]()
        for gtin in gtinsOrdered {
            gtinsAccountedForCount[gtin] = gtinOrderedCount(gtin) - gtinLoadedCount(gtin)
        }

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

        return itemsNotLoaded
    }

    var itemsOrdered: [Product] {
        var itemsOrdered = [Product]()
        for workOrder in workOrders.reverse() {
            if let products = workOrder.itemsOrdered {
                for product in products {
                    itemsOrdered.append(product)
                }
            }
        }

        return itemsOrdered
    }

    var itemsDelivered: [Product] {
        var itemsDelivered = [Product]()
        for workOrder in workOrders.reverse() {
            if let products = workOrder.itemsDelivered {
                for product in products {
                    itemsDelivered.append(product)
                }
            }
        }

        return itemsDelivered
    }

    var itemsRejected: [Product] {
        var itemsRejected = [Product]()
        for workOrder in workOrders.reverse() {
            if let products = workOrder.itemsRejected {
                for product in products {
                    itemsRejected.append(product)
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

    var scheduledStartAtDate: NSDate! {
        if let scheduledStartAt = scheduledStartAt {
            return NSDate.fromString(scheduledStartAt)
        }
        return nil
    }

    var scheduledEndAtDate: NSDate! {
        if let scheduledEndAt = scheduledEndAt {
            return NSDate.fromString(scheduledEndAt)
        }
        return nil
    }

    var startedAtDate: NSDate! {
        if let startedAt = startedAt {
            return NSDate.fromString(startedAt)
        }
        return nil
    }

    var endedAtDate: NSDate! {
        if let endedAt = endedAt {
            return NSDate.fromString(endedAt)
        }
        return nil
    }

    var loadingStartedAtDate: NSDate! {
        if let loadingStartedAt = loadingStartedAt {
            return NSDate.fromString(loadingStartedAt)
        }
        return nil
    }

    var loadingEndedAtDate: NSDate! {
        if let loadingEndedAt = loadingEndedAt {
            return NSDate.fromString(loadingEndedAt)
        }
        return nil
    }

    var unloadingStartedAtDate: NSDate! {
        if let unloadingStartedAt = unloadingStartedAt {
            return NSDate.fromString(unloadingStartedAt)
        }
        return nil
    }

    var unloadingEndedDate: NSDate! {
        if let unloadingEndedAt = unloadingEndedAt {
            return NSDate.fromString(unloadingEndedAt)
        }
        return nil
    }

    var humanReadableDuration: String! {
        var startedAtDate: NSDate!

        if let date = loadingStartedAtDate {
            startedAtDate = date
        } else if let date = self.startedAtDate {
            startedAtDate = date
        }

        if let startedAtDate = startedAtDate {
            var seconds = 0.0

            if let endedAtDate = endedAtDate {
                seconds = endedAtDate.timeIntervalSinceDate(startedAtDate)
            } else {
                seconds = NSDate().timeIntervalSinceDate(startedAtDate)
            }

            let hours = Int(floor(Double(seconds) / 3600.0))
            seconds = Double(seconds) % 3600.0
            let minutes = Int(floor(Double(seconds) / 60.0))
            seconds = floor(Double(seconds) % 60.0)

            let hoursString = hours >= 1 ? "\(hours):" : ""
            let minutesString = minutes < 10 ? "0\(minutes)" : "\(minutes)"
            let secondsString = seconds < 10 ? "0\(Int(seconds))" : "\(Int(seconds))"
            return "\(hoursString)\(minutesString):\(secondsString)"
        }
        return nil
    }

    var statusColor: UIColor {
        if status == "scheduled" {
            return Color.scheduledStatusColor()
        } else if status == "loading" {
            return Color.loadingStatusColor()
        } else if status == "in_progress" {
            return Color.inProgressStatusColor()
        } else if status == "unloading" {
            return Color.unloadingStatusColor()
        } else if status == "canceled" {
            return Color.canceledStatusColor()
        } else if status == "completed" {
            return Color.completedStatusColor()
        } else if status == "pending_completion" {
            return Color.pendingCompletionStatusColor()
        }

        return UIColor.clearColor()
    }

    func reload(onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().fetchRouteWithId(String(id), params: ["include_work_orders": "true"],
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
        ApiService.sharedService().updateRouteWithId(String(id), params: toDictionary(),
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
        ApiService.sharedService().updateRouteWithId(String(id), params: toDictionary(),
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
        ApiService.sharedService().updateRouteWithId(String(id), params: toDictionary(),
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
        ApiService.sharedService().updateRouteWithId(String(id), params: toDictionary(),
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
