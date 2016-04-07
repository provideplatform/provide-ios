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
    var categoryId = 0
    var category: Category!
    var companyId = 0
    var company: Company!
    var customerId = 0
    var customer: Customer!
    var comments: [Comment]!
    var jobId = 0
    var job: Job!
    var desc: String!
    var workOrderProviders: [WorkOrderProvider]!
    var scheduledStartAt: String!
    var startedAt: String!
    var endedAt: String!
    var abandonedAt: String!
    var canceledAt: String!
    var duration: NSNumber!
    var estimatedCost = -1.0
    var estimatedDuration: NSNumber!
    var estimatedSqFt = -1.0
    var status: String!
    var previewImage: UIImage!
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
    var supervisors: [User]!
    var tasks: [Task]!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
            "id": "id",
            "category_id": "categoryId",
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
        mapping.addRelationshipMappingWithSourceKeyPath("category", mapping: Category.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("company", mapping: Company.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("customer", mapping: Customer.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("job", mapping: Job.mapping())
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", withMapping: Attachment.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "comments", toKeyPath: "comments", withMapping: Comment.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "expenses", toKeyPath: "expenses", withMapping: Expense.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "items_ordered", toKeyPath: "itemsOrdered", withMapping: Product.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "items_delivered", toKeyPath: "itemsDelivered", withMapping: Product.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "items_rejected", toKeyPath: "itemsRejected", withMapping: Product.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "materials", toKeyPath: "materials", withMapping: WorkOrderProduct.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "supervisors", toKeyPath: "supervisors", withMapping: User.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "tasks", toKeyPath: "tasks", withMapping: Task.mapping()))
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

    var humanReadableEstimatedCost: String! {
        if estimatedCost > -1.0 {
            return "$\(NSString(format: "%.02f", estimatedCost))"
        }
        return nil
    }

    var humanReadableEstimatedSqFt: String! {
        if estimatedSqFt > -1.0 {
            return "\(NSString(format: "%.03f", estimatedSqFt)) sq ft"
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
        } else if status == "pending_approval" {
            return Color.pendingCompletionStatusColor()
        } else if status == "rejected" {
            return Color.abandonedStatusColor()
        }

        return UIColor.clearColor()
    }

    var materialsCost: Double! {
        if let materials = materials {
            var cost = 0.0
            for workOrderProduct in materials {
                let price = workOrderProduct.price > 0.0 ? workOrderProduct.price : (workOrderProduct.jobProduct != nil ? workOrderProduct.jobProduct.price : 0.0)
                cost += workOrderProduct.quantity * price
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

    var estimatedProvidersCost: Double {
        var estimatedCost = 0.0
        if let workOrderProviders = workOrderProviders {
            for workOrderProvider in workOrderProviders {
                if workOrderProvider.estimatedCost > -1.0 {
                    estimatedCost += workOrderProvider.estimatedCost
                }
            }
        }
        return estimatedCost
    }

    var estimatedProvidersDuration: Double {
        var estimatedDuration = 0.0
        if let workOrderProviders = workOrderProviders {
            for workOrderProvider in workOrderProviders {
                if workOrderProvider.estimatedCost > -1.0 {
                    estimatedDuration += (workOrderProvider.estimatedDuration / 3600.0)
                }
            }
        }
        return estimatedDuration
    }

    var providersCostDisposition: String! {
        let estimatedCost = estimatedProvidersCost
        let estimatedDuration = estimatedProvidersDuration
        var providersCostDisposition = "\(NSString(format: "%.02f", estimatedDuration)) hours"
        if estimatedCost > 0.0 {
            providersCostDisposition = "\(providersCostDisposition) totaling $\(NSString(format: "%.02f", estimatedCost))"
        }
        return providersCostDisposition
    }

    var expensesDisposition: String! {
        if expenses == nil {
            return nil
        }

        var expensesDisposition = "\(expensesCount) items"
        if let expensedAmount = expensedAmount {
            if expensedAmount > 0.0 {
                let expensedAmountString = NSString(format: "%.02f", expensedAmount)
                expensesDisposition = "\(expensesDisposition) totaling $\(expensedAmountString)"
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
            if let componentDict = component as? [String : AnyObject] {
                if let completed = componentDict["completed"] as? Bool {
                    if !completed {
                        componentIdentifier = componentDict["component"] as! String
                        break
                    }
                } else {
                    componentIdentifier = componentDict["component"] as! String
                    break
                }
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
                    imageCount += 1
                }
            }
        }
        return imageCount
    }

    var isCompleted: Bool {
        if let status = status {
            return status == "completed"
        }
        return false
    }

    var isCurrentUserProvider: Bool {
        let user = currentUser()
        for provider in providers {
            if provider.userId == user.id {
                return true
            }
        }
        return false
    }

    var providers: [Provider] {
        var providers = [Provider]()
        if let workOrderProviders = workOrderProviders {
            for workOrderProvider in workOrderProviders {
                providers.append(workOrderProvider.provider)
            }
        } else {
            workOrderProviders = [WorkOrderProvider]()
        }
        return providers
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
        if itemsOrdered == nil {
            return [String]()
        }
        return itemsOrdered.map { $0.gtin }
    }

    var gtinsDelivered: [String] {
        if itemsDelivered == nil {
            return [String]()
        }
        return itemsDelivered.map { $0.gtin }
    }

    var gtinsRejected: [String] {
        if itemsRejected == nil {
            return [String]()
        }
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
        dictionary.removeValueForKey("preview_image")
        dictionary.removeValueForKey("id")
        return dictionary
    }

    func addProvider(provider: Provider, flatFee: Double = -1.0, onSuccess: OnSuccess, onError: OnError) {
        if !hasProvider(provider) {
            let workOrderProvider = WorkOrderProvider()
            workOrderProvider.provider = provider
            if flatFee >= 0.0 {
                workOrderProvider.flatFee = flatFee
            }
            workOrderProviders.append(workOrderProvider)
            if id > 0 {
                save(onSuccess: onSuccess, onError: onError)
            }
        }
    }

    func updateWorkOrderProvider(workOrderProvider: WorkOrderProvider, onSuccess: OnSuccess, onError: OnError) {
        if let provider = workOrderProvider.provider {
            if hasProvider(provider) {
                var index: Int?
                for wop in workOrderProviders {
                    if wop.id == workOrderProvider.id || wop.provider.id == workOrderProvider.provider.id {
                        index = workOrderProviders.indexOfObject(wop)
                    }
                }
                if let index = index {
                    self.workOrderProviders.replaceRange(index...index, with: [workOrderProvider])

                    if id > 0 {
                        save(onSuccess: onSuccess, onError: onError)
                    }
                }
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
                var wop: [String : AnyObject] = ["provider_id": workOrderProvider.provider.id]
                if workOrderProvider.estimatedDuration > -1.0 {
                    wop.updateValue(workOrderProvider.estimatedDuration, forKey: "estimated_duration")
                }
                if workOrderProvider.hourlyRate > -1.0 {
                    wop.updateValue(workOrderProvider.hourlyRate, forKey: "hourly_rate")
                }
                if workOrderProvider.flatFee > -1.0 {
                    wop.updateValue(workOrderProvider.flatFee, forKey: "flat_fee")
                }
                if workOrderProvider.id > 0 {
                    wop.updateValue(workOrderProvider.id, forKey: "id")
                }
                workOrderProviders.append(wop)
            }
            params.updateValue(workOrderProviders, forKey: "work_order_providers")

            var materials = [[String : AnyObject]]()
            for workOrderProduct in self.materials {
                var wop: [String : AnyObject] = ["job_product_id": workOrderProduct.jobProductId, "quantity": workOrderProduct.quantity]
                if workOrderProduct.price > 0.0 {
                    wop.updateValue(workOrderProduct.price, forKey: "price")
                }
                if workOrderProduct.id > 0 {
                    wop.updateValue(workOrderProduct.id, forKey: "id")
                }
                materials.append(wop)
            }
            params.updateValue(materials, forKey: "materials")

            ApiService.sharedService().updateWorkOrderWithId(String(id), params: params,
                onSuccess: { statusCode, mappingResult in
                    WorkOrderService.sharedService().updateWorkOrder(self)
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
                var wop: [String : AnyObject] = ["job_product_id": workOrderProduct.jobProductId, "quantity": workOrderProduct.quantity]
                if workOrderProduct.price > 0.0 {
                    wop.updateValue(workOrderProduct.price, forKey: "price")
                }
                materials.append(wop)
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
        reload(["include_estimated_cost": "false", "include_job": "false", "include_supervisors": "true", "include_work_order_providers": "true"], onSuccess: onSuccess, onError: onError)
    }

    func reload(params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().fetchWorkOrderWithId(String(id), params: params,
            onSuccess: { statusCode, mappingResult in
                let workOrder = mappingResult.firstObject as! WorkOrder
                self.status = workOrder.status
                self.estimatedCost = workOrder.estimatedCost
                self.supervisors = workOrder.supervisors
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
                i += 1
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

    func restart(onSuccess: OnSuccess, onError: OnError) {
        updateWorkorderWithStatus("in_progress", onSuccess: onSuccess, onError: onError)
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

    func approve(onSuccess onSuccess: OnSuccess, onError: OnError) {
        complete(onSuccess: onSuccess, onError: onError)
    }

    func reject(onSuccess onSuccess: OnSuccess, onError: OnError) {
        updateWorkorderWithStatus("rejected", onSuccess: onSuccess, onError: onError)
    }

    func complete(onSuccess onSuccess: OnSuccess, onError: OnError) {
        updateWorkorderWithStatus("completed", onSuccess: onSuccess, onError: onError)
    }

    func submitForApproval(onSuccess onSuccess: OnSuccess, onError: OnError) {
        updateWorkorderWithStatus("pending_approval", onSuccess: onSuccess, onError: onError)
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
        if expenses == nil {
            expenses = [Expense]()
        }
        if expensedAmount == nil {
            expensedAmount = 0.0
        }
        expenses.insert(expense, atIndex: 0)
        expensesCount += 1
        if let amount = expensedAmount {
            expensedAmount = amount + expense.amount
            if estimatedCost > -1.0 {
                estimatedCost += expense.amount
            }
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
        ApiService.sharedService().addComment(comment, toWorkOrderWithId: String(id),
            onSuccess: { (statusCode, mappingResult) -> () in
                if self.comments == nil {
                    self.comments = [Comment]()
                }
                self.comments.insert(mappingResult.firstObject as! Comment, atIndex: 0)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { (error, statusCode, responseString) -> () in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func reloadComments(onSuccess: OnSuccess, onError: OnError) {
        if id > 0 {
            comments = [Comment]()
            ApiService.sharedService().fetchComments(forWorkOrderWithId: String(id),
                onSuccess: { statusCode, mappingResult in
                    let fetchedComments = (mappingResult.array() as! [Comment]).reverse()
                    for comment in fetchedComments {
                        self.comments.append(comment)
                    }
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        }
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
