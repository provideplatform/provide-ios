//
//  WorkOrder.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit
import KTSwiftExtensions

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
    var desc: String!
    var workOrderProviders: [WorkOrderProvider]!
    var scheduledStartAt: String!
    var scheduledEndAt: String!
    var startedAt: String!
    var dueAt: String!
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
    var config: NSMutableDictionary!
    var expensesCount = 0
    var expensedAmount: Double!
    var priority = 0
    var supervisors: [User]!
    var destination: Contact! // FIXME

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id": "id",
            "category_id": "categoryId",
            "company_id": "companyId",
            "customer_id": "customerId",
            "job_id": "jobId",
            "config": "config",
            "description": "desc",
            "destination": "destination",
            "scheduled_start_at": "scheduledStartAt",
            "scheduled_end_at": "scheduledEndAt",
            "started_at": "startedAt",
            "due_at": "dueAt",
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
            "priority": "priority",
            ])
        mapping?.addRelationshipMapping(withSourceKeyPath: "company", mapping: Company.mapping())
        mapping?.addRelationshipMapping(withSourceKeyPath: "customer", mapping: Customer.mapping())
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", with: Attachment.mappingWithRepresentations()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "comments", toKeyPath: "comments", with: Comment.mapping()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "supervisors", toKeyPath: "supervisors", with: User.mapping()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "work_order_providers", toKeyPath: "workOrderProviders", with: WorkOrderProvider.mapping()))

        return mapping!
    }

    var allowNewComments: Bool {
        return status != nil && status != "awaiting_schedule"
    }

    var annotation: Annotation {
        return Annotation(workOrder: self)
    }

    fileprivate var pendingArrival = false

    var canArrive: Bool {
        return !pendingArrival
    }

    var scheduledStartAtDate: Date! {
        if let scheduledStartAt = scheduledStartAt {
            return Date.fromString(scheduledStartAt)
        }
        return nil
    }

    var dueAtDate: Date! {
        if let dueAt = dueAt {
            return Date.fromString(dueAt)
        }
        return nil
    }

    var scheduledEndAtDate: Date! {
        if let scheduledEndAt = scheduledEndAt {
            return Date.fromString(scheduledEndAt)
        }
        return nil
    }

    var scheduledDueDate: Date! {
        return scheduledEndAtDate
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

    var abandonedAtDate: Date! {
        if let abandonedAt = abandonedAt {
            return Date.fromString(abandonedAt)
        }
        return nil
    }

    var canceledAtDate: Date! {
        if let canceledAt = canceledAt {
            return Date.fromString(canceledAt)
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

    var humanReadableDueAtTimestamp: String! {
        if let dueAtDate = dueAtDate {
            if isIPad() {
                return "\(dueAtDate.dayOfWeek), \(dueAtDate.monthName) \(dueAtDate.dayOfMonth) @ \(dueAtDate.timeString!)"
            } else {
                return "\(dueAtDate.month)/\(dueAtDate.dayOfMonth)/\(dueAtDate.year) @ \(dueAtDate.timeString!)"
            }
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

    var humanReadableScheduledEndAtTimestamp: String! {
        if let scheduledEndAtDate = scheduledEndAtDate {
            if isIPad() {
                return "\(scheduledEndAtDate.dayOfWeek), \(scheduledEndAtDate.monthName) \(scheduledEndAtDate.dayOfMonth) @ \(scheduledEndAtDate.timeString!)"
            } else {
                return "\(scheduledEndAtDate.month)/\(scheduledEndAtDate.dayOfMonth)/\(scheduledEndAtDate.year) @ \(scheduledEndAtDate.timeString!)"
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
        } else if status == "delayed" {
            return Color.enRouteStatusColor()
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

        return UIColor.clear
    }

    var canBeAbandoned: Bool {
        return true
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
        let user = currentUser
        for provider in providers {
            if provider.userId == user?.id {
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

    override func toDictionary(_ snakeKeys: Bool = true, includeNils: Bool = false, ignoreKeys: [String] = [String]()) -> [String : AnyObject] {
        var dictionary = super.toDictionary(ignoreKeys: ["job"])
        dictionary.removeValue(forKey: "config")
        dictionary.removeValue(forKey: "preview_image")
        dictionary.removeValue(forKey: "id")
        return dictionary
    }

    func addProvider(_ provider: Provider, flatFee: Double = -1.0, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if !hasProvider(provider) {
            let workOrderProvider = WorkOrderProvider()
            workOrderProvider.provider = provider
            if flatFee >= 0.0 {
                workOrderProvider.flatFee = flatFee
            }
            workOrderProviders.append(workOrderProvider)
            if id > 0 {
                save(onSuccess, onError: onError)
            }
        }
    }

    func updateWorkOrderProvider(_ workOrderProvider: WorkOrderProvider, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if let provider = workOrderProvider.provider {
            if hasProvider(provider) {
                var index: Int?
                for wop in workOrderProviders {
                    if wop.id == workOrderProvider.id || wop.provider.id == workOrderProvider.provider.id {
                        index = workOrderProviders.indexOfObject(wop)
                    }
                }
                if let index = index {
                    self.workOrderProviders.replaceSubrange(index...index, with: [workOrderProvider])

                    if id > 0 {
                        save(onSuccess, onError: onError)
                    }
                }
            }
        }
    }

    func mergeAttachment(_ attachment: Attachment) {
        if attachments == nil {
            attachments = [Attachment]()
        }

        var replaced = false
        var index = 0
        for a in attachments {
            if a.id == attachment.id {
                self.attachments[index] = attachment
                replaced = true
                break
            }
            index += 1
        }

        if !replaced {
            attachments.append(attachment)
        }
    }

    func removeProvider(_ provider: Provider, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if hasProvider(provider) {
            removeProvider(provider)
            if id > 0 {
                save(onSuccess, onError: onError)
            }
        }
    }

    func save(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var params = toDictionary()

        if id > 0 {
            if self.workOrderProviders == nil {
                self.workOrderProviders = [WorkOrderProvider]()
            }
            var workOrderProviders = [[String : AnyObject]]()
            for workOrderProvider in self.workOrderProviders {
                var wop: [String : AnyObject] = ["provider_id": workOrderProvider.provider.id as AnyObject]
                if workOrderProvider.estimatedDuration > -1.0 {
                    wop.updateValue(workOrderProvider.estimatedDuration as AnyObject, forKey: "estimated_duration")
                }
                if workOrderProvider.hourlyRate > -1.0 {
                    wop.updateValue(workOrderProvider.hourlyRate as AnyObject, forKey: "hourly_rate")
                }
                if workOrderProvider.flatFee > -1.0 {
                    wop.updateValue(workOrderProvider.flatFee as AnyObject, forKey: "flat_fee")
                }
                if workOrderProvider.id > 0 {
                    wop.updateValue(workOrderProvider.id as AnyObject, forKey: "id")
                }
                workOrderProviders.append(wop)
            }
            params.updateValue(workOrderProviders as AnyObject, forKey: "work_order_providers")

            ApiService.sharedService().updateWorkOrderWithId(String(id), params: params,
                onSuccess: { statusCode, mappingResult in
                    WorkOrderService.sharedService().updateWorkOrder(self)
                    onSuccess(statusCode, mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error, statusCode, responseString)
                }
            )
        } else {
            var workOrderProviders = [[String : AnyObject]]()
            for provider in providers {
                workOrderProviders.append(["provider_id": provider.id as AnyObject])
            }
            params.updateValue(workOrderProviders as AnyObject, forKey: "work_order_providers")

            if let _ = scheduledStartAt {
                params.updateValue("scheduled" as AnyObject, forKey: "status")
            }

            ApiService.sharedService().createWorkOrder(params,
                onSuccess: { statusCode, mappingResult in
                    let workOrder = mappingResult?.firstObject as! WorkOrder
                    self.id = workOrder.id
                    self.status = workOrder.status
                    WorkOrderService.sharedService().updateWorkOrder(workOrder)
                    onSuccess(statusCode, mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error, statusCode, responseString)
                }
            )
        }
    }

    func reload(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        reload(["include_estimated_cost": "false" as AnyObject, "include_job": "false" as AnyObject, "include_supervisors": "true" as AnyObject, "include_work_order_providers": "true" as AnyObject], onSuccess: onSuccess, onError: onError)
    }

    func reload(_ params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if id > 0 {
            ApiService.sharedService().fetchWorkOrderWithId(String(id), params: params,
                onSuccess: { statusCode, mappingResult in
                    let workOrder = mappingResult?.firstObject as! WorkOrder
                    self.status = workOrder.status
                    self.estimatedCost = workOrder.estimatedCost
                    self.supervisors = workOrder.supervisors
                    self.workOrderProviders = workOrder.workOrderProviders
                    WorkOrderService.sharedService().updateWorkOrder(mappingResult?.firstObject as! WorkOrder)
                    onSuccess(statusCode, mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error, statusCode, responseString)
                }
            )
        }
    }

    func reloadAttachments(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if id > 0 {
            ApiService.sharedService().fetchAttachments(forWorkOrderWithId: String(id),
                onSuccess: { statusCode, mappingResult in
                    self.attachments = mappingResult?.array() as! [Attachment]
                    onSuccess(statusCode, mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error, statusCode, responseString)
                }
            )
        }
    }

    func hasProvider(_ provider: Provider) -> Bool {
        for p in providers {
            if p.id == provider.id {
                return true
            }
        }
        return false
    }

    func removeProvider(_ provider: Provider) {
        if hasProvider(provider) {
            var i = -1
            for p in providers {
                i += 1
                if p.id == provider.id {
                    break
                }
            }
            workOrderProviders.remove(at: i)
        }
    }

    func setComponents(_ components: NSMutableArray) {
        let mutableConfig = NSMutableDictionary(dictionary: config)
        mutableConfig.setObject(components, forKey: "components" as NSCopying)
        config = mutableConfig
    }

    func start(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        updateWorkorderWithStatus("en_route", onSuccess: onSuccess, onError: onError)
    }

    func restart(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        updateWorkorderWithStatus("in_progress", onSuccess: onSuccess, onError: onError)
    }

    func arrive(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        self.pendingArrival = true

        updateWorkorderWithStatus("in_progress",
            onSuccess: { statusCode, mappingResult in
                self.pendingArrival = false
                onSuccess(statusCode, mappingResult)
            },
            onError: { error, statusCode, responseString in
                self.pendingArrival = false
                onError(error, statusCode, responseString)
            }
        )
    }

    func abandon(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        updateWorkorderWithStatus("abandoned", onSuccess: onSuccess, onError: onError)
    }

    func cancel(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        updateWorkorderWithStatus("canceled", onSuccess: onSuccess, onError: onError)
    }

    func approve(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        complete(onSuccess, onError: onError)
    }

    func reject(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        updateWorkorderWithStatus("rejected", onSuccess: onSuccess, onError: onError)
    }

    func complete(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        updateWorkorderWithStatus("completed", onSuccess: onSuccess, onError: onError)
    }

    func submitForApproval(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        updateWorkorderWithStatus("pending_approval", onSuccess: onSuccess, onError: onError)
    }

    func updateWorkorderWithStatus(_ status: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        self.status = status
        ApiService.sharedService().updateWorkOrderWithId(String(id), params: ["status": status as AnyObject],
            onSuccess: { statusCode, mappingResult in
                WorkOrderService.sharedService().updateWorkOrder(self)
                onSuccess(statusCode, mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error, statusCode, responseString)
            }
        )
    }

    func attach(
        _ image: UIImage,
        params: [String: AnyObject],
        onSuccess: @escaping KTApiSuccessHandler,
        onError: @escaping KTApiFailureHandler)
    {
        let data = UIImageJPEGRepresentation(image, 1.0)!

        ApiService.sharedService().addAttachment(data, withMimeType: "image/jpg", toWorkOrderWithId: String(id), params: params,
            onSuccess: { response in
                if self.attachments == nil {
                    self.attachments = [Attachment]()
                }
                self.attachments.append(response?.firstObject as! Attachment)
                onSuccess(response)
            },
            onError: { error, statusCode, responseString in
                onError(error, statusCode, responseString)
            }
        )
    }

    func addComment(_ comment: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        ApiService.sharedService().addComment(comment, toWorkOrderWithId: String(id),
            onSuccess: { (statusCode, mappingResult) -> () in
                if self.comments == nil {
                    self.comments = [Comment]()
                }
                self.comments.insert(mappingResult?.firstObject as! Comment, at: 0)
                onSuccess(statusCode, mappingResult)
            },
            onError: { (error, statusCode, responseString) -> () in
                onError(error, statusCode, responseString)
            }
        )
    }

    func reloadComments(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if id > 0 {
            comments = [Comment]()
            ApiService.sharedService().fetchComments(forWorkOrderWithId: String(id),
                onSuccess: { statusCode, mappingResult in
                    let fetchedComments = (mappingResult?.array() as! [Comment]).reversed()
                    for comment in fetchedComments {
                        self.comments.append(comment)
                    }
                    onSuccess(statusCode, mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error, statusCode, responseString)
                }
            )
        }
    }

    func scoreProvider(_ netPromoterScore: NSNumber, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        providerRating = netPromoterScore
        ApiService.sharedService().updateWorkOrderWithId(String(id), params: ["provider_rating": providerRating],
            onSuccess: { statusCode, mappingResult in
                WorkOrderService.sharedService().updateWorkOrder(self)
                onSuccess(statusCode, mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error, statusCode, responseString)
            }
        )
    }

    class Annotation: NSObject, MKAnnotation {
        fileprivate var workOrder: WorkOrder!

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
