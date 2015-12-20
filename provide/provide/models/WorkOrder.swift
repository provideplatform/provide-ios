//
//  WorkOrder.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class WorkOrder: Model {

    var id = 0
    var companyId = 0
    var company: Company!
    var customerId = 0
    var customer: Customer!
    var jobId = 0
    var job: Job!
    var desc: String!
    var workOrderProviders = [WorkOrderProvider]()
    var scheduledStartAt: String!
    var startedAt: String!
    var endedAt: String!
    var abandonedAt: String!
    var canceledAt: String!
    var duration: NSNumber!
    var estimatedCost: NSNumber!
    var estimatedDuration: NSNumber!
    var status: String!
    var providerRating: NSNumber!
    var customerRating: NSNumber!
    var attachments: [Attachment]!
    var annotations: [provide.Annotation]!
    var config: NSMutableDictionary!
    var expenses: [Expense]!
    var expensesCount = 0
    var expensedAmount: Double!
    var itemsOrdered: [Product]!
    var itemsDelivered: [Product]!
    var itemsRejected: [Product]!
    var materials: [WorkOrderProduct]!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "company_id": "companyId",
            "customer_id": "customerId",
            "job_id": "jobId",
            "config": "config",
            "description": "desc",
            "scheduled_start_at": "scheduledStartAt",
            "started_at": "startedAt",
            "ended_at": "endedAt",
            "abandoned_at": "abandonedAt",
            "canceled_at": "canceledAt",
            "duration": "duration",
            "estimated_cost": "estimatedCost",
            "estimated_duration": "estimatedDuration",
            "status": "status",
            "provider_rating": "providerRating",
            "customer_rating": "customerRating",
            "expenses_count": "expensesCount",
            "expensed_amount": "expensedAmount",
            ])
        mapping.addRelationshipMappingWithSourceKeyPath("company", mapping: Company.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("customer", mapping: Customer.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("job", mapping: Job.mapping())
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", withMapping: Attachment.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "expenses", toKeyPath: "expenses", withMapping: Expense.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "items_ordered", toKeyPath: "itemsOrdered", withMapping: Product.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "items_delivered", toKeyPath: "itemsDelivered", withMapping: Product.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "items_rejected", toKeyPath: "itemsRejected", withMapping: Product.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "materials", toKeyPath: "materials", withMapping: WorkOrderProduct.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "work_order_providers", toKeyPath: "workOrderProviders", withMapping: WorkOrderProvider.mapping()))

        return mapping
    }

    var annotation: Annotation {
        return Annotation(workOrder: self)
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

    var humanReadableScheduledStartAtTimestamp: String! {
        if let scheduledStartAtDate = scheduledStartAtDate {
            if isIPad() {
                return "\(scheduledStartAtDate.dayOfWeek), \(scheduledStartAtDate.monthName) \(scheduledStartAtDate.dayOfMonth) @ \(scheduledStartAtDate.timeString!)"
            } else {
                return "\(scheduledStartAtDate.month)/\(scheduledStartAtDate.dayOfMonth)/\(scheduledStartAtDate.year) @ \(scheduledStartAtDate.timeString!)"
            }
        }
        return nil
    }

    var humanReadableStartedAtTimestamp: String! {
        if let startedAtDate = startedAtDate {
            return "\(startedAtDate.dayOfWeek), \(startedAtDate.monthName) \(startedAtDate.dayOfMonth) @ \(startedAtDate.timeString!)"
        }
        return nil
    }

    var statusColor: UIColor {
        if status == "awaiting_schedule" {
            return Color.awaitingScheduleStatusColor()
        } else if status == "scheduled" {
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

    var materialsCost: Double! {
        if let materials = materials {
            var cost = 0.0
            for workOrderProduct in materials {
                cost += workOrderProduct.quantity * workOrderProduct.price
            }
            return cost
        }
        return nil
    }

    var inventoryDisposition: String! {
        if let materialsCost = materialsCost {
            return "$\(NSString(format: "%.02f", materialsCost))"
        } else if itemsDelivered != nil && itemsOrdered != nil {
            return "\(itemsDelivered.count) of \(itemsOrdered.count) items delivered"
        }
        return nil
    }

    var expensesDisposition: String! {
        if expenses == nil {
            return nil
        }

        var expensesDisposition = "\(expensesCount) items"
        if let expensedAmount = expensedAmount {
            if expensedAmount > 0.0 {
                expensesDisposition = "\(expensesDisposition) totaling $\(expensedAmount)"
            }
        }
        return expensesDisposition
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

    var providers: [Provider] {
        var providers = [Provider]()
        for workOrderProvider in workOrderProviders {
            providers.append(workOrderProvider.provider)
        }
        return providers //workOrderProviders.map({ [unowned $0: workOrderProvider] in $0.provider })
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

    override func toDictionary(snakeKeys: Bool = true, includeNils: Bool = false, ignoreKeys: [String] = [String]()) -> [String : AnyObject] {
        var dictionary = super.toDictionary(ignoreKeys: ["job"])
        dictionary.removeValueForKey("config")
        dictionary.removeValueForKey("id")
        return dictionary
    }

    func addProvider(provider: Provider, onSuccess: OnSuccess, onError: OnError) {
        if !hasProvider(provider) {
            let workOrderProvider = WorkOrderProvider()
            workOrderProvider.provider = provider
            workOrderProviders.append(workOrderProvider)
            if id > 0 {
                save(onSuccess: onSuccess, onError: onError)
            }
        }
    }

    func removeProvider(provider: Provider, onSuccess: OnSuccess, onError: OnError) {
        if hasProvider(provider) {
            removeProvider(provider)
            if id > 0 {
                save(onSuccess: onSuccess, onError: onError)
            }
        }
    }

    func save(onSuccess onSuccess: OnSuccess, onError: OnError) {
        var params = toDictionary()

        if id > 0 {
            var workOrderProviders = [[String : AnyObject]]()
            for workOrderProvider in self.workOrderProviders {
                var wop = ["provider_id": workOrderProvider.provider.id]
                if workOrderProvider.id > 0 {
                    wop.updateValue(workOrderProvider.id, forKey: "id")
                }
                workOrderProviders.append(wop)
            }
            params.updateValue(workOrderProviders, forKey: "work_order_providers")

            var materials = [[String : AnyObject]]()
            for workOrderProduct in self.materials {
                var wop: [String : AnyObject] = ["job_product_id": workOrderProduct.jobProductId, "quantity": workOrderProduct.quantity]
                if workOrderProduct.id > 0 {
                    wop.updateValue(workOrderProduct.id, forKey: "id")
                }
                materials.append(wop)
            }
            params.updateValue(materials, forKey: "materials")

            ApiService.sharedService().updateWorkOrderWithId(String(id), params: params,
                onSuccess: { statusCode, mappingResult in
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        } else {
            var workOrderProviders = [[String : AnyObject]]()
            for provider in providers {
                workOrderProviders.append(["provider_id": provider.id])
            }
            params.updateValue(workOrderProviders, forKey: "work_order_providers")

            var materials = [[String : AnyObject]]()
            for workOrderProduct in self.materials {
                materials.append(["job_product_id": workOrderProduct.jobProductId, "quantity": workOrderProduct.quantity])
            }
            params.updateValue(materials, forKey: "materials")

            if let _ = scheduledStartAt {
                params.updateValue("scheduled", forKey: "status")
            }

            ApiService.sharedService().createWorkOrder(params,
                onSuccess: { statusCode, mappingResult in
                    let workOrder = mappingResult.firstObject as! WorkOrder
                    self.id = workOrder.id
                    self.status = workOrder.status
                    WorkOrderService.sharedService().updateWorkOrder(workOrder)
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        }
    }

    func reload(onSuccess onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().fetchWorkOrderWithId(String(id),
            onSuccess: { statusCode, mappingResult in
                let workOrder = mappingResult.firstObject as! WorkOrder
                self.status = workOrder.status
                self.workOrderProviders = workOrder.workOrderProviders
                WorkOrderService.sharedService().updateWorkOrder(mappingResult.firstObject as! WorkOrder)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func reloadJob(onSuccess: OnSuccess, onError: OnError) {
        if id > 0 && jobId > 0 {
            ApiService.sharedService().fetchJobWithId(String(jobId),
                onSuccess: { statusCode, mappingResult in
                    self.job = mappingResult.firstObject as! Job
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        }
    }

    func reloadAttachments(onSuccess: OnSuccess, onError: OnError) {
        if id > 0 {
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
    }

    func reloadExpenses(onSuccess: OnSuccess, onError: OnError) {
        if id > 0 {
            ApiService.sharedService().fetchExpenses(forWorkOrderWithId: String(id),
                onSuccess: { statusCode, mappingResult in
                    self.expenses = mappingResult.array() as! [Expense]
                    self.expensesCount = self.expenses.count
                    self.expensedAmount = 0.0
                    for expense in self.expenses {
                        self.expensedAmount = self.expensedAmount + expense.amount
                    }
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        }
    }

    func reloadInventory(onSuccess: OnSuccess, onError: OnError) {
        if id > 0 {

        }
    }

    func hasProvider(provider: Provider) -> Bool {
        for p in providers {
            if p.id == provider.id {
                return true
            }
        }
        return false
    }

    func removeProvider(provider: Provider) {
        if hasProvider(provider) {
            var i = -1
            for p in providers {
                i++
                if p.id == provider.id {
                    break
                }
            }
            workOrderProviders.removeAtIndex(i)
        }
    }

    func workOrderProductForJobProduct(jobProduct: JobProduct) -> WorkOrderProduct! {
        for workOrderProduct in materials {
            if workOrderProduct.jobProductId == jobProduct.id {
                return workOrderProduct
            }
        }
        return nil
    }

    func addWorkOrderProductForJobProduct(jobProduct: JobProduct, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) {
        if workOrderProductForJobProduct(jobProduct) == nil && materials != nil {
            let workOrderProduct = WorkOrderProduct()
            workOrderProduct.workOrderId = id
            workOrderProduct.jobProductId = jobProduct.id
            workOrderProduct.jobProduct = jobProduct

            if let quantity = params["quantity"] as? Double {
                workOrderProduct.quantity = quantity
            }

            if let price = params["price"] as? Double {
                workOrderProduct.price = price
            }

            materials.append(workOrderProduct)

            save(onSuccess:
                { statusCode, mappingResult in
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                    //                    let saveMappingResult = mappingResult
                    //                    self.reloadMaterials(
                    //                        { statusCode, mappingResult in
                    //                            onSuccess(statusCode: statusCode, mappingResult: saveMappingResult)
                    //                        },
                    //                        onError: { error, statusCode, responseString in
                    //                            onError(error: error, statusCode: statusCode, responseString: responseString)
                    //                        }
                    //                    )
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        }
    }

    func removeWorkOrderProductForProduct(jobProduct: JobProduct, onSuccess: OnSuccess, onError: OnError) {
        if let workOrderProduct = workOrderProductForJobProduct(jobProduct) {
            removeWorkOrderProduct(workOrderProduct, onSuccess: onSuccess, onError: onError)
        }
    }
    
    func removeWorkOrderProduct(workOrderProduct: WorkOrderProduct, onSuccess: OnSuccess, onError: OnError) {
        materials.removeObject(workOrderProduct)
        save(onSuccess: onSuccess, onError: onError)
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

        ApiService.sharedService().addAttachment(data, withMimeType: "image/jpg", toWorkOrderWithId: String(id), params: params,
            onSuccess: { statusCode, mappingResult in
                if self.attachments == nil {
                    self.attachments = [Attachment]()
                }
                self.attachments.append(mappingResult.firstObject as! Attachment)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func prependExpense(expense: Expense) {
        if self.expenses == nil {
            self.expenses = [Expense]()
        }
        self.expenses.insert(expense, atIndex: 0)
        self.expensesCount += 1
        if let amount = self.expensedAmount {
            self.expensedAmount = amount + expense.amount
        }
    }

    func addExpense(params: [String: AnyObject], receipt: UIImage!, onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().createExpense(params, forExpensableType: "work_order",
            withExpensableId: String(self.id), onSuccess: { statusCode, mappingResult in
                let expenseStatusCode = statusCode
                let expenseMappingResult = mappingResult
                let expense = mappingResult.firstObject as! Expense

                self.prependExpense(expense)

                if let receipt = receipt {
                    expense.attach(receipt, params: params,
                        onSuccess: { (statusCode, mappingResult) -> () in
                            onSuccess(statusCode: expenseStatusCode, mappingResult: expenseMappingResult)
                        },
                        onError: { (error, statusCode, responseString) -> () in
                            onError(error: error, statusCode: statusCode, responseString: responseString)
                        }
                    )
                } else {
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                }
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
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

    class Annotation: NSObject, MKAnnotation {
        private var workOrder: WorkOrder!

        required init(workOrder: WorkOrder) {
            self.workOrder = workOrder
        }

        @objc var coordinate: CLLocationCoordinate2D {
            return workOrder.coordinate
        }

        // Title and subtitle for use by selection UI.
        @objc var title: String? {
            return nil //workOrder.title
        }

        @objc var subtitle: String? {
            return nil //workOrder.subtitle
        }
    }
}
