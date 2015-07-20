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
    var attachments: NSArray!
    var components: NSMutableArray!
    var itemsOrdered: NSMutableArray!
    var itemsDelivered: NSMutableArray!
    var itemsRejected: NSMutableArray!

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
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", withMapping: Attachment.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "items_ordered", toKeyPath: "itemsOrdered", withMapping: Product.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "items_delivered", toKeyPath: "itemsDelivered", withMapping: Product.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "items_rejected", toKeyPath: "itemsRejected", withMapping: Product.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "work_order_providers", toKeyPath: "workOrderProviders", withMapping: WorkOrderProvider.mapping()))

        return mapping
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
            itemsOnTruck.append(itemOrdered as! Product)
        }
        for itemRejected in itemsRejected {
            itemsOnTruck.append(itemRejected as! Product)
        }

        var newItemsOnTruck = NSMutableArray(array: itemsOnTruck)

        for gtinDelivered in gtinsDelivered {
            for (i, item) in enumerate(newItemsOnTruck) {
                if gtinDelivered == (item as! Product).gtin {
                    newItemsOnTruck.removeObjectAtIndex(i)
                    break
                }
            }
        }

        for gtinRejected in gtinsRejected {
            for (i, item) in enumerate(newItemsOnTruck) {
                if gtinRejected == (item as! Product).gtin {
                    newItemsOnTruck.removeObjectAtIndex(i)
                    break
                }
            }
        }

        itemsOnTruck = [Product]()
        for item in newItemsOnTruck {
            itemsOnTruck.append(item as! Product)
        }

        return itemsOnTruck
    }

    var regionIdentifier: String {
        return "work order \(id)"
    }

    var regionMonitoringRadius: CLLocationDistance {
        return 50.0
    }

    func rejectItem(item: Product, onSuccess: OnSuccess, onError: OnError) {
        var newItemsDelivered = [Product]()
        for product in itemsDelivered.reverseObjectEnumerator().allObjects {
            newItemsDelivered.append(product as! Product)
        }
        newItemsDelivered.removeObject(item)
        itemsDelivered = NSMutableArray(array: newItemsDelivered.reverse())

        item.rejected = true
        itemsRejected.addObject(item)

        updateManifest(onSuccess: onSuccess, onError: onError)
    }

    func deliverItem(item: Product, onSuccess: OnSuccess, onError: OnError) {
        if item.rejected {
            var newItemsRejected = [Product]()
            for product in itemsRejected {
                newItemsRejected.append(product as! Product)
            }
            newItemsRejected.removeObject(item)
            itemsRejected = NSMutableArray(array: newItemsRejected)
        }

        item.rejected = false
        itemsDelivered.addObject(item)

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
            gtinsOrdered.append((product as! Product).gtin)
        }
        return gtinsOrdered
    }

    var gtinsDelivered: [String] {
        var gtinsDelivered = [String]()
        for product in itemsDelivered {
            gtinsDelivered.append((product as! Product).gtin)
        }
        return gtinsDelivered
    }

    var gtinsRejected: [String] {
        var gtinsRejected = [String]()
        for product in itemsRejected {
            gtinsRejected.append((product as! Product).gtin)
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

    func addComment(comment: String, onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().addComment(comment,
            toWorkOrderWithId: id.stringValue,
            onSuccess: onSuccess,
            onError: onError)
    }

    func scoreProvider(netPromoterScore: NSNumber, onSuccess: OnSuccess, onError: OnError) {
        providerRating = netPromoterScore
        ApiService.sharedService().updateWorkOrderWithId(id, params: ["provider_rating": providerRating], onSuccess: onSuccess, onError: onError)
    }
}
