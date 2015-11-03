//
//  WorkOrder.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class WorkOrder: Model, MKAnnotation {

    var id = 0
    var companyId = 0
    var company: Company!
    var customerId = 0
    var customer: Customer!
    var job: Job!
    var desc: String!
    var workOrderProviders = [WorkOrderProvider]()
    var scheduledStartAt: String!
    var startedAt: String!
    var endedAt: String!
    var abandonedAt: String!
    var canceledAt: String!
    var duration: NSNumber!
    var estimatedDuration: NSNumber!
    var status: String!
    var providerRating: NSNumber!
    var customerRating: NSNumber!
    var attachments: [Attachment]!
    var config: NSMutableDictionary!
    var itemsOrdered: [Product]!
    var itemsDelivered: [Product]!
    var itemsRejected: [Product]!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "company_id": "companyId",
            "customer_id": "customerId",
            "config": "config",
            "description": "desc",
            "scheduled_start_at": "scheduledStartAt",
            "started_at": "startedAt",
            "ended_at": "endedAt",
            "abandoned_at": "abandonedAt",
            "canceled_at": "canceledAt",
            "duration": "duration",
            "estimated_duration": "estimatedDuration",
            "status": "status",
            "provider_rating": "providerRating",
            "customer_rating": "customerRating",
            ])
        mapping.addRelationshipMappingWithSourceKeyPath("company", mapping: Company.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("customer", mapping: Customer.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("job", mapping: Job.mapping())
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", withMapping: Attachment.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "items_ordered", toKeyPath: "itemsOrdered", withMapping: Product.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "items_delivered", toKeyPath: "itemsDelivered", withMapping: Product.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "items_rejected", toKeyPath: "itemsRejected", withMapping: Product.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "work_order_providers", toKeyPath: "workOrderProviders", withMapping: WorkOrderProvider.mapping()))

        return mapping
    }

    private var pendingArrival = false

    var canArrive: Bool {
        return !pendingArrival
    }

    var blueprintImageUrl: NSURL! {
        if let job = job {
            return job.blueprintImageUrl
        }
        return nil
    }

    var scheduledStartAtDate: NSDate! {
        if let scheduledStartAt = scheduledStartAt {
            return NSDate.fromString(scheduledStartAt)
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

    var abandonedAtDate: NSDate! {
        if let abandonedAt = abandonedAt {
            return NSDate.fromString(abandonedAt)
        }
        return nil
    }

    var canceledAtDate: NSDate! {
        if let canceledAt = canceledAt {
            return NSDate.fromString(canceledAt)
        }
        return nil
    }

    var humanReadableDuration: String! {
        if let startedAtDate = startedAtDate {
            var seconds = 0.0

            var endedAtDate = self.endedAtDate

            if let date = endedAtDate {
                endedAtDate = date
            } else if let date = abandonedAtDate {
                endedAtDate = date
            } else if let date = canceledAtDate {
                endedAtDate = date
            }

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
        } else if status == "en_route" {
            return Color.enRouteStatusColor()
        } else if status == "in_progress" {
            return Color.inProgressStatusColor()
        } else if status == "canceled" {
            return Color.canceledStatusColor()
        } else if status == "completed" {
            return Color.completedStatusColor()
        } else if status == "abandoned" {
            return Color.abandonedStatusColor()
        }

        return UIColor.clearColor()
    }

    var inventoryDisposition: String! {
        if itemsDelivered != nil && itemsOrdered != nil {
            return "\(itemsDelivered.count) of \(itemsOrdered.count) items delivered"
        }
        return nil
    }

    var canBeDelivered: Bool {
        let itemsOrderedCount = (itemsOrdered != nil) ? itemsOrdered.count : 0
        let itemsDeliveredCount = (itemsDelivered != nil) ? itemsDelivered.count : 0
        let itemsRejectedCount = (itemsRejected != nil) ? itemsRejected.count : 0

        return itemsOrderedCount == itemsDeliveredCount + itemsRejectedCount
    }

    var canBeAbandoned: Bool {
        let itemsOrderedCount = (itemsOrdered != nil) ? itemsOrdered.count : 0
        return itemsOrderedCount == itemsOnTruck.count
    }

    var contact: Contact! {
        return customer.contact
    }

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(customer.contact.latitude.doubleValue,
                                          customer.contact.longitude.doubleValue)
    }

    var components: NSMutableArray {
        if let config = config {
            if let components = config["components"] as? NSMutableArray {
                return components
            }
        }
        return NSMutableArray()
    }

    var currentComponentIdentifier: String! {
        var componentIdentifier: String!
        for component in components {
            if let completed = component["completed"] as? Bool {
                if !completed {
                    componentIdentifier = component["component"] as! String
                    break
                }
            } else {
                componentIdentifier = component["component"] as! String
                break
            }
        }
        return componentIdentifier
    }

    var itemsOnTruck: [Product] {
        var itemsOnTruck = [Product]()
        for itemOrdered in itemsOrdered {
            let product = Product(string: itemOrdered.toJSONString(true))
            itemsOnTruck.append(product)
        }

        for (_, itemDelivered) in itemsDelivered.enumerate() {
            for (x, itemOnTruck) in itemsOnTruck.enumerate() {
                if itemOnTruck.gtin == itemDelivered.gtin {
                    itemsOnTruck.removeAtIndex(x)
                    break
                }
            }
        }

        for itemRejected in itemsRejected {
            itemsOnTruck.append(itemRejected)
        }

        for (_, itemRejected) in itemsRejected.enumerate() {
            for (x, itemOnTruck) in itemsOnTruck.enumerate() {
                if itemOnTruck.gtin == itemRejected.gtin {
                    itemsOnTruck.removeAtIndex(x)
                    break
                }
            }
        }

        return itemsOnTruck
    }

    var imageCount: Int {
        var imageCount = 0
        if let attachments = attachments {
            for attachment in attachments {
                if attachment.mimeType == "image/png" || attachment.mimeType == "image/jpg" || attachment.mimeType == "image/jpeg" {
                    imageCount++
                }
            }
        }
        return imageCount
    }

    var regionIdentifier: String {
        return "work order \(id)"
    }

    var regionMonitoringRadius: CLLocationDistance {
        return 50.0
    }

    func rejectItem(item: Product, onSuccess: OnSuccess, onError: OnError) {
        itemsDelivered.removeObject(item)

        item.rejected = true
        itemsRejected.append(item)

        updateManifest(onSuccess, onError: onError)
    }

    func deliverItem(item: Product, onSuccess: OnSuccess, onError: OnError) {
        itemsRejected.removeObject(item)

        item.rejected = false
        itemsDelivered.append(item)

        updateManifest(onSuccess, onError: onError)
    }

    func canUnloadGtin(gtin: String!) -> Bool {
        return gtinOrderedCount(gtin) > gtinDeliveredCount(gtin)
    }

    func canRejectGtin(gtin: String!) -> Bool {
        return gtinDeliveredCount(gtin) > 0
    }

    var gtinsOrdered: [String] {
        return itemsOrdered.map { $0.gtin }
    }

    var gtinsDelivered: [String] {
        return itemsDelivered.map { $0.gtin }
    }

    var gtinsRejected: [String] {
        return itemsRejected.map { $0.gtin }
    }

    func gtinOrderedCount(gtin: String!) -> Int {
        return gtinsOrdered.count
    }

    func gtinRejectedCount(gtin: String!) -> Int {
        return gtinsRejected.count
    }

    func gtinDeliveredCount(gtin: String!) -> Int {
        return gtinsDelivered.count
    }

    func reload(onSuccess onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().fetchWorkOrderWithId(String(id),
            onSuccess: { statusCode, mappingResult in
                WorkOrderService.sharedService().updateWorkOrder(mappingResult.firstObject as! WorkOrder)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func reloadAttachments(onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().fetchAttachments(forWorkOrderWithId: String(id),
            onSuccess: { statusCode, mappingResult in
                self.attachments = mappingResult.array() as! [Attachment]
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func setComponents(components: NSMutableArray) {
        let mutableConfig = NSMutableDictionary(dictionary: config)
        mutableConfig.setObject(components, forKey: "components")
        config = mutableConfig
    }

    func start(onSuccess: OnSuccess, onError: OnError) {
        updateWorkorderWithStatus("en_route", onSuccess: onSuccess, onError: onError)
    }

    func arrive(onSuccess onSuccess: OnSuccess, onError: OnError) {
        self.pendingArrival = true

        updateWorkorderWithStatus("in_progress",
            onSuccess: { statusCode, mappingResult in
                self.pendingArrival = false
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                self.pendingArrival = false
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func abandon(onSuccess onSuccess: OnSuccess, onError: OnError) {
        updateWorkorderWithStatus("abandoned", onSuccess: onSuccess, onError: onError)
    }

    func cancel(onSuccess onSuccess: OnSuccess, onError: OnError) {
        updateWorkorderWithStatus("canceled", onSuccess: onSuccess, onError: onError)
    }

    func reject(onSuccess onSuccess: OnSuccess, onError: OnError) {
        updateWorkorderWithStatus("rejected", onSuccess: onSuccess, onError: onError)
    }

    func complete(onSuccess onSuccess: OnSuccess, onError: OnError) {
        updateWorkorderWithStatus("completed", onSuccess: onSuccess, onError: onError)
    }

    func updateWorkorderWithStatus(status: String, onSuccess: OnSuccess, onError: OnError) {
        self.status = status
        ApiService.sharedService().updateWorkOrderWithId(String(id), params: ["status": status],
            onSuccess: { statusCode, mappingResult in
                WorkOrderService.sharedService().updateWorkOrder(self)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func updateManifest() {
        updateManifest(
            { statusCode, mappingResult in

            },
            onError: { error, statusCode, responseString in

            }
        )
    }

    func updateManifest(onSuccess: OnSuccess, onError: OnError) {
        let params = [
            "gtins_delivered": gtinsDelivered,
            "gtins_rejected": gtinsRejected
        ]

        ApiService.sharedService().updateWorkOrderWithId(String(id), params: params,
            onSuccess: { statusCode, mappingResult in
                WorkOrderService.sharedService().updateWorkOrder(self)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func attach(image: UIImage, params: [String: AnyObject], onSuccess: OnSuccess, onError: OnError) {
        let data = UIImageJPEGRepresentation(image, 1.0)!

        ApiService.sharedService().addAttachment(data,
            withMimeType: "image/jpg",
            toWorkOrderWithId: String(id),
            params: params,
            onSuccess: onSuccess,
            onError: onError)
    }

    func addComment(comment: String, onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().addComment(comment,
            toWorkOrderWithId: String(id),
            onSuccess: onSuccess,
            onError: onError)
    }

    func scoreProvider(netPromoterScore: NSNumber, onSuccess: OnSuccess, onError: OnError) {
        providerRating = netPromoterScore
        ApiService.sharedService().updateWorkOrderWithId(String(id), params: ["provider_rating": providerRating],
            onSuccess: { statusCode, mappingResult in
                WorkOrderService.sharedService().updateWorkOrder(self)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }
}
