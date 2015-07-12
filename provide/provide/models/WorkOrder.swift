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
    var startedAt: String!
    var endedAt: String!
    var duration: NSNumber!
    var estimatedDuration: NSNumber!
    var status: String!
    var providerRating: NSNumber!
    var customerRating: NSNumber!
    // var attachments = [AnyObject]() // Unusud
    var components = [[String: AnyObject]]()
    var itemsOrdered = [Product]()
    var itemsDelivered = [Product]()
    var itemsRejected = [Product]()
    var itemsUnloaded = [Product]()

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
            ]
        )

        mapping.addRelationshipMappingWithSourceKeyPath("company", mapping: Company.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("customer", mapping: Customer.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("attachments", mapping: Attachment.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("items_ordered", mapping: Product.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("items_delivered", mapping: Product.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("items_rejected", mapping: Product.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("items_unloaded", mapping: Product.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("work_order_providers", mapping: WorkOrderProvider.mapping())

        return mapping
    }

    var canBeDelivered: Bool {
        return !canBeRejected && itemsOrdered.count == itemsUnloaded.count + itemsRejected.count
    }

    var canBeRejected: Bool {
        return itemsOrdered.count == itemsRejected.count
    }

    var contact: Contact {
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
        var remainingItemsOnTruck = itemsOrdered

        for item in itemsUnloaded {
            remainingItemsOnTruck.removeObject(item)
        }

        return remainingItemsOnTruck
    }

    var regionIdentifier: String {
        return "work order \(id)"
    }

    var regionMonitoringRadius: CLLocationDistance {
        return 50.0
    }

    func rejectItem(item: Product) {
        itemsRejected.addObject(item)
    }

    func approveItem(item: Product) {
        let newItemsRejected = NSMutableArray(array: itemsRejected)

        for (i, rejectedItem) in enumerate(itemsRejected) {
            if (rejectedItem as! Product).gtin == item.gtin {
                newItemsRejected.removeObjectAtIndex(i)
                itemsRejected = newItemsRejected
                break
            }
        }
    }

    func unloadItem(item: Product) {
        itemsUnloaded.append(item)
    }

    func loadItem(item: Product) {
        itemsUnloaded.removeObject(item)
    }

    func canUnloadGtin(gtin: String) -> Bool {
        return gtinOrderedCount(gtin) > gtinUnloadedCount(gtin)
    }

    func canRejectGtin(gtin: String) -> Bool {
        return gtinOrderedCount(gtin) > gtinRejectedCount(gtin)
    }

    var gtinsDelivered: [String] {
        return itemsUnloaded.map { $0.gtin }
    }

    var gtinsRejected: [String] {
        var gtinsRejected = [String]()
        for product in itemsRejected {
            gtinsRejected.append((product as! Product).gtin)
        }
        return gtinsRejected
    }

    func gtinRejectedCount(gtin: String!) -> Int {
        var gtinRejectedCount = 0
        for product in itemsRejected {
            if (product as! Product).gtin == gtin {
                gtinRejectedCount += 1
            }
        }
        return gtinRejectedCount
    }

    func gtinOrderedCount(gtin: String) -> Int {
        return itemsOrdered.filter { $0.gtin == gtin }.count
    }

    func gtinUnloadedCount(gtin: String) -> Int {
        return itemsUnloaded.filter { $0.gtin == gtin }.count
    }

    func reload(onSuccess onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().fetchWorkOrderWithId(id, onSuccess: onSuccess, onError: onError)
    }

    func start(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "en_route"
        ApiService.sharedService().updateWorkOrderWithId(id, params: ["status": status], onSuccess: onSuccess, onError: onError)
    }

    func arrive(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "in_progress"
        ApiService.sharedService().updateWorkOrderWithId(id, params: ["status": status], onSuccess: onSuccess, onError: onError)
    }

    func abandon(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "abandoned"
        ApiService.sharedService().updateWorkOrderWithId(id, params: ["status": status], onSuccess: onSuccess, onError: onError)
    }

    func cancel(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "canceled"
        ApiService.sharedService().updateWorkOrderWithId(id, params: ["status": status], onSuccess: onSuccess, onError: onError)
    }

    func reject(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "rejected"
        ApiService.sharedService().updateWorkOrderWithId(id, params: ["status": status], onSuccess: onSuccess, onError: onError)
    }

    func complete(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "completed"
        ApiService.sharedService().updateWorkOrderWithId(id, params: ["status": status], onSuccess: onSuccess, onError: onError)
    }

    func updateDeliveredItems(onSuccess onSuccess: OnSuccess, onError: OnError) {
        let params = [
            "gtins_delivered": gtinsDelivered,
            "gtins_rejected": gtinsRejected
        ]

        ApiService.sharedService().updateWorkOrderWithId(id, params: params, onSuccess: onSuccess, onError: onError)
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

    func scoreProvider(netPromoterScore: NSNumber, onSuccess: OnSuccess, onError: OnError) {
        providerRating = netPromoterScore
        ApiService.sharedService().updateWorkOrderWithId(id, params: ["provider_rating": providerRating], onSuccess: onSuccess, onError: onError)
    }
}
