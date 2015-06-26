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
    var workOrderProviders = NSArray()
    var startedAt: String!
    var endedAt: String!
    var duration: NSNumber!
    var estimatedDuration: NSNumber!
    var status: String!
    var providerRating: NSNumber!
    var customerRating: NSNumber!
    var attachments = NSArray()
    var components = NSMutableArray()
    var itemsOrdered = NSMutableArray()
    var itemsDelivered = NSMutableArray()
    var itemsRejected = NSMutableArray()
    var itemsUnloaded = NSMutableArray()

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "company_id": "companyId",
            "customer_id": "customerId",
            "description": "desc",
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
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "items_unloaded", toKeyPath: "itemsUnloaded", withMapping: Product.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "work_order_providers", toKeyPath: "workOrderProviders", withMapping: WorkOrderProvider.mapping()))

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
        for component in components.objectEnumerator().allObjects {
            if let completed = component.objectForKey("completed") as? Bool {
                if !completed {
                    componentIdentifier = component.objectForKey("component") as! String
                    break
                }
            } else {
                componentIdentifier = component.objectForKey("component") as! String
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

        let newItemsOnTruck = NSMutableArray(array: itemsOnTruck)

        var gtinsUnloaded = [String]()
        for itemUnloaded in itemsUnloaded {
            gtinsUnloaded.append((itemUnloaded as! Product).gtin)
        }

        while gtinsUnloaded.count > 0 {
            let gtin = gtinsUnloaded.removeAtIndex(0)

            for (i, item) in newItemsOnTruck.enumerate() {
                if gtin == (item as! Product).gtin {
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

    func rejectItem(item: Product) {
        itemsRejected.addObject(item)
    }

    func approveItem(item: Product) {
        let newItemsRejected = NSMutableArray(array: itemsRejected)

        for (i, rejectedItem) in itemsRejected.enumerate() {
            if item.gtin == (rejectedItem as! Product).gtin {
                newItemsRejected.removeObjectAtIndex(i)
                itemsRejected = newItemsRejected
                break
            }
        }
    }

    func unloadItem(item: Product) {
        itemsUnloaded.addObject(item)
    }

    func loadItem(item: Product) {
        let newItemsUnloaded = NSMutableArray(array: itemsUnloaded)

        for (i, unloadedItem) in itemsUnloaded.enumerate() {
            if (unloadedItem as! Product).gtin == item.gtin {
                newItemsUnloaded.removeObjectAtIndex(i)
                itemsUnloaded = newItemsUnloaded
                break
            }
        }
    }

    func canUnloadGtin(gtin: String) -> Bool {
        return gtinOrderedCount(gtin) > gtinUnloadedCount(gtin)
    }

    func canRejectGtin(gtin: String) -> Bool {
        return gtinOrderedCount(gtin) > gtinRejectedCount(gtin)
    }

    var gtinsDelivered: [String] {
        var gtinsDelivered = [String]()
        for product in itemsUnloaded {
            gtinsDelivered.append((product as! Product).gtin)
        }
        return gtinsDelivered
    }

    func gtinRejectedCount(gtin: String) -> Int {
        var gtinRejectedCount = 0
        for product in itemsRejected {
            if (product as! Product).gtin == gtin {
                gtinRejectedCount += 1
            }
        }
        return gtinRejectedCount
    }

    func gtinOrderedCount(gtin: String) -> Int {
        var gtinOrderedCount = 0
        for product in itemsOrdered {
            if (product as! Product).gtin == gtin {
                gtinOrderedCount += 1
            }
        }
        return gtinOrderedCount
    }

    func gtinUnloadedCount(gtin: String) -> Int {
        var gtinUnloadedCount = 0
        for product in itemsUnloaded {
            if (product as! Product).gtin == gtin {
                gtinUnloadedCount += 1
            }
        }
        return gtinUnloadedCount
    }

    func reload(onSuccess onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().fetchWorkOrderWithId(id.description, onSuccess: onSuccess, onError: onError)
    }

    func start(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "en_route"
        ApiService.sharedService().updateWorkOrderWithId(id.description, params: toDictionary(), onSuccess: onSuccess, onError: onError)
    }

    func arrive(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "in_progress"
        ApiService.sharedService().updateWorkOrderWithId(id.description, params: toDictionary(), onSuccess: onSuccess, onError: onError)
    }

    func abandon(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "abandoned"
        ApiService.sharedService().updateWorkOrderWithId(id.description, params: toDictionary(), onSuccess: onSuccess, onError: onError)
    }

    func cancel(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "canceled"
        ApiService.sharedService().updateWorkOrderWithId(id.description, params: toDictionary(), onSuccess: onSuccess, onError: onError)
    }

    func reject(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "rejected"
        ApiService.sharedService().updateWorkOrderWithId(id.description, params: toDictionary(), onSuccess: onSuccess, onError: onError)
    }

    func complete(onSuccess onSuccess: OnSuccess, onError: OnError) {
        status = "completed"
        ApiService.sharedService().updateWorkOrderWithId(id.description, params: toDictionary(), onSuccess: onSuccess, onError: onError)
    }

    func updateDeliveredItems(onSuccess onSuccess: OnSuccess, onError: OnError) {
        let params = [
            "gtins_delivered": gtinsDelivered
        ]

        ApiService.sharedService().updateWorkOrderWithId(id.description, params: params, onSuccess: onSuccess, onError: onError)
    }

    func attach(image: UIImage, params: NSDictionary, onSuccess: OnSuccess, onError: OnError) {
        let data = UIImageJPEGRepresentation(image, 1.0)!

        ApiService.sharedService().addAttachment(data,
            withMimeType: "image/jpg",
            toWorkOrderWithId: id.description,
            params: params,
            onSuccess: onSuccess,
            onError: onError)
    }

    func scoreProvider(netPromoterScore: NSNumber, onSuccess: OnSuccess, onError: OnError) {
        providerRating = netPromoterScore
        ApiService.sharedService().updateWorkOrderWithId(id.description, params: toDictionary(), onSuccess: onSuccess, onError: onError)
    }
}
