//
//  Route.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

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
    var incompleteManifest: NSNumber!
    var currentLegIndex = 0
    var dispatcherOriginAssignment: NSDictionary!
    var providerOriginAssignment: ProviderOriginAssignment!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
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
            ])

        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "provider_origin_assignment", toKeyPath: "providerOriginAssignment", with: ProviderOriginAssignment.mapping()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "items_loaded", toKeyPath: "itemsLoaded", with: Product.mapping()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "work_orders", toKeyPath: "workOrders", with: WorkOrder.mapping()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "leg", toKeyPath: "legs", with: RouteLeg.mapping()))
        return mapping!
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

    func updateWorkOrder(_ workOrder: WorkOrder) {
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

    var overviewPolyline: MKPolyline {
        var coords = [CLLocationCoordinate2D]()
        for leg in legs {
            for step in leg.steps {
                if let shapes = step.shape {
                    for shape in shapes {
                        let shapeCoords = shape.components(separatedBy: ",")
                        let latitude = shapeCoords.count > 0 ? (shapeCoords.first! as NSString).doubleValue : 0.0
                        let longitude = shapeCoords.count > 1 ? (shapeCoords.last! as NSString).doubleValue : 0.0
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

        for workOrder in workOrders.reversed() {
            if let products = workOrder.itemsOrdered {
                for product in products {
                    let gtin = product.gtin
                    if let remainingToLoad = gtinsAccountedForCount[gtin!] {
                        if remainingToLoad > 0 {
                            itemsNotLoaded.append(product)
                            gtinsAccountedForCount[gtin!] = remainingToLoad - 1
                        }
                    }
                }
            }
        }

        return itemsNotLoaded
    }

    var itemsOrdered: [Product] {
        var itemsOrdered = [Product]()
        for workOrder in workOrders.reversed() {
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
        for workOrder in workOrders.reversed() {
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
        for workOrder in workOrders.reversed() {
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

    func gtinOrderedCount(_ gtin: String) -> Int {
        return itemsOrdered.filter { $0.gtin == gtin }.count
    }

    func gtinLoadedCount(_ gtin: String) -> Int {
        return gtinsLoaded.filter { $0 == gtin }.count
    }

    var itemsToUnloadCountRemaining: Int! {
        return itemsLoaded.count
    }

    func itemForGtin(_ gtin: String) -> Product? {
        for item in itemsOrdered {
            if item.gtin == gtin {
                return item
            }
        }
        return nil
    }

    func isGtinRequired(_ gtin: String) -> Bool {
        return gtinOrderedCount(gtin) > gtinLoadedCount(gtin)
    }

    var scheduledStartAtDate: Date! {
        if let scheduledStartAt = scheduledStartAt {
            return Date.fromString(scheduledStartAt)
        }
        return nil
    }

    var scheduledEndAtDate: Date! {
        if let scheduledEndAt = scheduledEndAt {
            return Date.fromString(scheduledEndAt)
        }
        return nil
    }

    var startedAtDate: Date! {
        if let startedAt = startedAt {
            return Date.fromString(startedAt)
        }
        return nil
    }

    var endedAtDate: Date! {
        if let endedAt = endedAt {
            return Date.fromString(endedAt)
        }
        return nil
    }

    var loadingStartedAtDate: Date! {
        if let loadingStartedAt = loadingStartedAt {
            return Date.fromString(loadingStartedAt)
        }
        return nil
    }

    var loadingEndedAtDate: Date! {
        if let loadingEndedAt = loadingEndedAt {
            return Date.fromString(loadingEndedAt)
        }
        return nil
    }

    var unloadingStartedAtDate: Date! {
        if let unloadingStartedAt = unloadingStartedAt {
            return Date.fromString(unloadingStartedAt)
        }
        return nil
    }

    var unloadingEndedDate: Date! {
        if let unloadingEndedAt = unloadingEndedAt {
            return Date.fromString(unloadingEndedAt)
        }
        return nil
    }

    var humanReadableDuration: String! {
        var startedAtDate: Date!

        if let date = loadingStartedAtDate {
            startedAtDate = date
        } else if let date = startedAtDate {
            startedAtDate = date
        }

        if let startedAtDate = startedAtDate {
            var seconds = 0.0

            if let endedAtDate = endedAtDate {
                seconds = endedAtDate.timeIntervalSince(startedAtDate)
            } else {
                seconds = Date().timeIntervalSince(startedAtDate)
            }

            let hours = Int(floor(Double(seconds) / 3600.0))
            seconds = Double(seconds).truncatingRemainder(dividingBy: 3600.0)
            let minutes = Int(floor(Double(seconds) / 60.0))
            seconds = floor(Double(seconds).truncatingRemainder(dividingBy: 60.0))

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

        return UIColor.clear
    }

    func reload(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        ApiService.sharedService().fetchRouteWithId(String(id), params: ["include_products": "true" as AnyObject, "include_work_orders": "true" as AnyObject],
            onSuccess: { statusCode, mappingResult in
                RouteService.sharedService().updateRoute(mappingResult?.firstObject as! Route)
                onSuccess(statusCode, mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error, statusCode, responseString)
            }
        )
    }

    func load(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        status = "loading"
        ApiService.sharedService().updateRouteWithId(String(id), params: toDictionary(),
            onSuccess: { statusCode, mappingResult in
                RouteService.sharedService().updateRoute(self)
                onSuccess(statusCode, mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error, statusCode, responseString)
            }
        )
    }

    func start(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        status = "in_progress"
        ApiService.sharedService().updateRouteWithId(String(id), params: toDictionary(),
            onSuccess: { statusCode, mappingResult in
                RouteService.sharedService().updateRoute(self)
                onSuccess(statusCode, mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error, statusCode, responseString)
            }
        )
    }

    func arrive(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        status = "unloading"
        ApiService.sharedService().updateRouteWithId(String(id), params: toDictionary(),
            onSuccess: { statusCode, mappingResult in
                RouteService.sharedService().updateRoute(self)
                onSuccess(statusCode, mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error, statusCode, responseString)
            }
        )
    }

    func complete(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        status = "pending_completion"
        ApiService.sharedService().updateRouteWithId(String(id), params: toDictionary(),
            onSuccess: { statusCode, mappingResult in
                RouteService.sharedService().updateRoute(self)
                onSuccess(statusCode, mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error, statusCode, responseString)
            }
        )
    }

    func loadManifestItemByGtin(_ gtin: String!, onSuccess: OnSuccess!, onError: OnError!) {
        RouteService.loadManifestItemByGtin(gtin, onRoute: self, onSuccess: onSuccess, onError: onError)
    }

    func unloadManifestItemByGtin(_ gtin: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        RouteService.unloadManifestItemByGtin(gtin, onRoute: self, onSuccess: onSuccess, onError: onError)
    }
}
