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
    var desc: String!
    var workOrderProviders = [WorkOrderProvider]()
    var scheduledStartAt: String!
    var startedAt: String!
    var endedAt: String!
    var duration: NSNumber!
    var estimatedDuration: NSNumber!
    var status: String!
    var providerRating: NSNumber!
    var customerRating: NSNumber!
    var attachments: [Attachment]!
    var components: NSMutableArray!
    var itemsOrdered: [Product]!
    var itemsDelivered: [Product]!
    var itemsRejected: [Product]!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromArray([
            "id",
            "company_id",
            "customer_id",
            "started_at",
            "ended_at",
            "duration",
            "estimated_duration",
            "status",
            "provider_rating",
            "customer_rating",
            "components",
            ]
        )

        mapping.addAttributeMappingsFromDictionary([
            "description": "desc",
            "scheduled_start_at": "scheduledStartAt",
            "started_at": "startedAt",
            "ended_at": "endedAt",
            "duration": "duration",
            "estimated_duration": "estimatedDuration",
            "status": "status",
            "provider_rating": "providerRating",
            "customer_rating": "customerRating",
            "components": "components"
            ])
        mapping.addRelationshipMappingWithSourceKeyPath("company", mapping: Company.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("customer", mapping: Customer.mapping())
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", withMapping: Attachment.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "items_ordered", toKeyPath: "itemsOrdered", withMapping: Product.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "items_delivered", toKeyPath: "itemsDelivered", withMapping: Product.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "items_rejected", toKeyPath: "itemsRejected", withMapping: Product.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "work_order_providers", toKeyPath: "workOrderProviders", withMapping: WorkOrderProvider.mapping()))

        return mapping
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

    var humanReadableDuration: String! {
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
            itemsOnTruck.append(itemOrdered)
        }
        for itemRejected in itemsRejected {
            itemsOnTruck.append(itemRejected)
        }

        for (i, itemDelivered) in enumerate(itemsDelivered) {
            for (x, itemOnTruck) in enumerate(itemsOnTruck) {
                if itemOnTruck.gtin == itemDelivered.gtin {
                    itemsOnTruck.removeAtIndex(x)
                    break
                }
            }
        }

        for (i, itemRejected) in enumerate(itemsRejected) {
            for (x, itemOnTruck) in enumerate(itemsOnTruck) {
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

    func rejectItem(var item: Product, onSuccess: OnSuccess, onError: OnError) {
        for (i, product) in enumerate(itemsDelivered) {
            if item.gtin == product.gtin {
                item = itemsDelivered.removeAtIndex(i)
                break
            }
        }

        item.rejected = true
        itemsRejected.append(item)

        updateManifest(onSuccess: onSuccess, onError: onError)
    }

    func deliverItem(var item: Product, onSuccess: OnSuccess, onError: OnError) {
        if item.rejected {
            for (i, product) in enumerate(itemsRejected) {
                if item.gtin == product.gtin {
                    item = itemsRejected.removeAtIndex(i)
                    break
                }
            }
        }

        item.rejected = false
        itemsDelivered.append(item)

        updateManifest(onSuccess: onSuccess, onError: onError)
    }

    func canUnloadGtin(gtin: String!) -> Bool {
        return gtinOrderedCount(gtin) > gtinDeliveredCount(gtin)
    }

    func canRejectGtin(gtin: String!) -> Bool {
        return gtinDeliveredCount(gtin) > 0
    }

    var gtinsOrdered: [String] {
        var gtinsOrdered = [String]()
        for product in itemsOrdered {
            gtinsOrdered.append(product.gtin)
        }
        return gtinsOrdered
    }

    var gtinsDelivered: [String] {
        var gtinsDelivered = [String]()
        for product in itemsDelivered {
            gtinsDelivered.append(product.gtin)
        }
        return gtinsDelivered
    }

    var gtinsRejected: [String] {
        var gtinsRejected = [String]()
        for product in itemsRejected {
            gtinsRejected.append(product.gtin)
        }
        return gtinsRejected
    }

    func gtinOrderedCount(gtin: String!) -> Int {
        var gtinOrderedCount = 0
        for gtinOrdered in gtinsOrdered {
            gtinOrderedCount += 1
        }
        return gtinOrderedCount
    }

    func gtinRejectedCount(gtin: String!) -> Int {
        var gtinRejectedCount = 0
        for gtinRejected in gtinsRejected {
            gtinRejectedCount += 1
        }
        return gtinRejectedCount
    }

    func gtinDeliveredCount(gtin: String!) -> Int {
        var gtinDeliveredCount = 0
        for gtinDelivered in gtinsDelivered {
            gtinDeliveredCount += 1
        }
        return gtinDeliveredCount
    }

    func reload(onSuccess onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().fetchWorkOrderWithId(id.stringValue,
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
        ApiService.sharedService().fetchAttachments(forWorkOrderWithId: id.stringValue,
            onSuccess: { statusCode, mappingResult in
                self.attachments = mappingResult.array() as! [Attachment]
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func start(onSuccess: OnSuccess, onError: OnError) {
        status = "en_route"
        ApiService.sharedService().updateWorkOrderWithId(id.stringValue, params: ["status": status],
            onSuccess: { statusCode, mappingResult in
                WorkOrderService.sharedService().updateWorkOrder(self)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func arrive(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "in_progress"
        ApiService.sharedService().updateWorkOrderWithId(id.stringValue, params: ["status": status],
            onSuccess: { statusCode, mappingResult in
                WorkOrderService.sharedService().updateWorkOrder(self)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func abandon(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "abandoned"
        ApiService.sharedService().updateWorkOrderWithId(id.stringValue, params: ["status": status],
            onSuccess: { statusCode, mappingResult in
                WorkOrderService.sharedService().updateWorkOrder(self)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func cancel(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "canceled"
        ApiService.sharedService().updateWorkOrderWithId(id.stringValue, params: ["status": status],
            onSuccess: { statusCode, mappingResult in
                WorkOrderService.sharedService().updateWorkOrder(self)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func reject(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "rejected"
        ApiService.sharedService().updateWorkOrderWithId(id.stringValue, params: ["status": status],
            onSuccess: { statusCode, mappingResult in
                WorkOrderService.sharedService().updateWorkOrder(self)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func complete(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "completed"
        ApiService.sharedService().updateWorkOrderWithId(id.stringValue, params: ["status": status],
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
            onSuccess: { statusCode, mappingResult in

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

        ApiService.sharedService().updateWorkOrderWithId(id.stringValue, params: params,
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
            toWorkOrderWithId: id,
            params: params,
            onSuccess: onSuccess,
            onError: onError)
    }

    func addComment(comment: String, onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().addComment(comment,
            toWorkOrderWithId: id.stringValue,
            onSuccess: onSuccess,
            onError: onError)
    }

    func scoreProvider(netPromoterScore: NSNumber, onSuccess: OnSuccess, onError: OnError) {
        providerRating = netPromoterScore
        ApiService.sharedService().updateWorkOrderWithId(id.stringValue, params: ["provider_rating": providerRating],
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
