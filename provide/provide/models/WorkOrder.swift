//
//  WorkOrder.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit

@objcMembers
class WorkOrder: Model {

    var id = 0
    var categoryId = 0
    var category: Category!
    var userId = 0
    var user: User!
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
    var estimatedPrice = -1.0
    var estimatedDistance: NSNumber!
    var estimatedDuration: NSNumber!
    var estimatedSqFt = -1.0
    var status: String!
    var previewImage: UIImage!
    var providerRating: NSNumber!
    var customerRating: NSNumber!
    var attachments: [Attachment]!
    var config: [String: AnyObject]!
    var configJson: String!
    var expensesCount = 0
    var expensedAmount: Double!
    var priority = 0
    var supervisors: [User]!

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id": "id",
            "category_id": "categoryId",
            "job_id": "jobId",
            "config": "config",
            "description": "desc",
            "scheduled_start_at": "scheduledStartAt",
            "scheduled_end_at": "scheduledEndAt",
            "started_at": "startedAt",
            "due_at": "dueAt",
            "ended_at": "endedAt",
            "abandoned_at": "abandonedAt",
            "canceled_at": "canceledAt",
            "duration": "duration",
            "estimated_cost": "estimatedCost",
            "estimated_distance": "estimatedDistance",
            "estimated_duration": "estimatedDuration",
            "estimated_price": "estimatedPrice",
            "status": "status",
            "provider_rating": "providerRating",
            "customer_rating": "customerRating",
            "expenses_count": "expensesCount",
            "expensed_amount": "expensedAmount",
            "priority": "priority",
            "user_id": "userId",
        ])
        mapping?.addRelationshipMapping(withSourceKeyPath: "user", mapping: User.mapping())
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

    private var pendingArrival = false

    var canArrive: Bool {
        return !pendingArrival && status == "en_route"
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
        guard let startedAtDate = startedAtDate else { return nil }

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
        guard let scheduledStartAtDate = scheduledStartAtDate else { return nil }

        if isIPad() {
            return "\(scheduledStartAtDate.dayOfWeek), \(scheduledStartAtDate.monthName) \(scheduledStartAtDate.dayOfMonth) @ \(scheduledStartAtDate.timeString!)"
        } else {
            return "\(scheduledStartAtDate.month)/\(scheduledStartAtDate.dayOfMonth)/\(scheduledStartAtDate.year) @ \(scheduledStartAtDate.timeString!)"
        }
    }

    var humanReadableScheduledEndAtTimestamp: String! {
        guard let scheduledEndAtDate = scheduledEndAtDate else { return nil }

        if isIPad() {
            return "\(scheduledEndAtDate.dayOfWeek), \(scheduledEndAtDate.monthName) \(scheduledEndAtDate.dayOfMonth) @ \(scheduledEndAtDate.timeString!)"
        } else {
            return "\(scheduledEndAtDate.month)/\(scheduledEndAtDate.dayOfMonth)/\(scheduledEndAtDate.year) @ \(scheduledEndAtDate.timeString!)"
        }
    }

    var humanReadableStartedAtTimestamp: String! {
        guard let startedAtDate = startedAtDate else { return nil }
        return "\(startedAtDate.dayOfWeek), \(startedAtDate.monthName) \(startedAtDate.dayOfMonth) @ \(startedAtDate.timeString!)"
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

        return .clear
    }

    var canBeAbandoned: Bool {
        return true
    }

    var contact: Contact! {
        return user.contact
    }

    var coordinate: CLLocationCoordinate2D! {
        if let config = config {
            if status == "in_progress" {
                if let destination = config["destination"] as? [String: AnyObject] {
                    let latitude = destination["latitude"] as? Double
                    let longitude = destination["longitude"] as? Double
                    if let latitude = latitude, let longitude = longitude {
                        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    }
                }
            } else {
                if let currentLocation = config["current_location"] as? [String: Double] {
                    let latitude = currentLocation["latitude"]
                    let longitude = currentLocation["longitude"]
                    if let latitude = latitude, let longitude = longitude {
                        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    }
                } else if let origin = config["origin"] as? [String: AnyObject] {
                    let latitude = origin["latitude"] as? Double
                    let longitude = origin["longitude"] as? Double
                    if let latitude = latitude, let longitude = longitude {
                        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    }
                }
            }
        }

        if let user = user {
            return CLLocationCoordinate2D(latitude: user.contact.latitude.doubleValue, longitude: user.contact.longitude.doubleValue)
        }

        return nil
    }

    var components: NSMutableArray {
        if let config = config, let components = config["components"] as? NSMutableArray {
            return components
        }
        return NSMutableArray()
    }

    var currentComponentIdentifier: String! {
        var componentIdentifier: String!
        for component in components {
            if let componentDict = component as? [String: AnyObject] {
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
        for provider in providers where provider.userId == user?.id {
            return true
        }
        return false
    }

    var isCurrentProviderTimedOut: Bool {
        if isCurrentUserProvider {
            if let workOrderProviders = workOrderProviders {
                for workOrderProvider in workOrderProviders where workOrderProvider.provider.userId == currentUser.id && workOrderProvider.isTimedOut {
                    return true
                }
            }
        }
        return false
    }

    var provider: Provider? {  // HACK-- looks for non-timed out providers... this should be done a lot better than this...
        if let workOrderProviders = workOrderProviders {
            for workOrderProvider in workOrderProviders where !workOrderProvider.isTimedOut {
                if let provider = workOrderProvider.provider {
                    return provider
                }
            }
        }
        return nil
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

    var providerProfileImageUrl: URL? {
        return provider?.profileImageUrl
    }

    var regionIdentifier: String {
        return "work order \(id)"
    }

    var regionMonitoringRadius: CLLocationDistance {
        return 10.0
    }

    override func toDictionary(_ snakeKeys: Bool = true, includeNils: Bool = false, ignoreKeys: [String] = [String]()) -> [String: AnyObject] {
        var dictionary = super.toDictionary(ignoreKeys: ["job"])
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
                save(onSuccess: onSuccess, onError: onError)
            }
        }
    }

    func updateWorkOrderProvider(_ workOrderProvider: WorkOrderProvider, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        guard let provider = workOrderProvider.provider else { return }

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
                    save(onSuccess: onSuccess, onError: onError)
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
                save(onSuccess: onSuccess, onError: onError)
            }
        }
    }

    func save(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var params = toDictionary()

        if let categoryId = params["category_id"] as? Int, categoryId == 0 {
            params["category_id"] = nil
        }

        if let jobId = params["job_id"] as? Int, jobId == 0 {
            params["job_id"] = nil
        }

        if let userId = params["user_id"] as? Int, userId == 0 {
            params["user_id"] = nil
        }

        if id > 0 {
            if self.workOrderProviders == nil {
                self.workOrderProviders = [WorkOrderProvider]()
            }
            var workOrderProviders = [[String: AnyObject]]()
            for workOrderProvider in self.workOrderProviders {
                var wop: [String: AnyObject] = ["provider_id": workOrderProvider.provider.id as AnyObject]
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

            ApiService.shared.updateWorkOrderWithId(String(id), params: params, onSuccess: { statusCode, mappingResult in
                WorkOrderService.shared.updateWorkOrder(self)
                onSuccess(statusCode, mappingResult)
            }, onError: onError)
        } else {
            var workOrderProviders = [[String: AnyObject]]()
            for provider in providers {
                workOrderProviders.append(["provider_id": provider.id as AnyObject])
            }
            params.updateValue(workOrderProviders as AnyObject, forKey: "work_order_providers")

            if scheduledStartAt != nil {
                params.updateValue("scheduled" as AnyObject, forKey: "status")
            }

            ApiService.shared.createWorkOrder(params, onSuccess: { statusCode, mappingResult in
                let workOrder = mappingResult?.firstObject as! WorkOrder
                self.id = workOrder.id
                self.status = workOrder.status
                WorkOrderService.shared.updateWorkOrder(workOrder)
                onSuccess(statusCode, mappingResult)
            }, onError: onError)
        }
    }

    func reload(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        reload(["include_estimated_cost": "false" as AnyObject, "include_job": "false" as AnyObject, "include_supervisors": "true" as AnyObject, "include_work_order_providers": "true" as AnyObject], onSuccess: onSuccess, onError: onError)
    }

    func reload(_ params: [String: AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if id > 0 {
            ApiService.shared.fetchWorkOrderWithId(String(id), params: params, onSuccess: { statusCode, mappingResult in
                let workOrder = mappingResult?.firstObject as! WorkOrder
                self.status = workOrder.status
                self.estimatedCost = workOrder.estimatedCost
                self.supervisors = workOrder.supervisors
                self.workOrderProviders = workOrder.workOrderProviders
                WorkOrderService.shared.updateWorkOrder(mappingResult?.firstObject as! WorkOrder)
                onSuccess(statusCode, mappingResult)
            }, onError: onError)
        }
    }

    func reloadAttachments(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if id > 0 {
            ApiService.shared.fetchAttachments(forWorkOrderWithId: String(id), onSuccess: { statusCode, mappingResult in
                self.attachments = mappingResult?.array() as! [Attachment]
                onSuccess(statusCode, mappingResult)
            }, onError: onError)
        }
    }

    func hasProvider(_ provider: Provider) -> Bool {
        for p in providers where p.id == provider.id {
            return true
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
        config = mutableConfig as! [String: AnyObject]
    }

    func route(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        updateWorkOrderWithStatus("en_route", onSuccess: onSuccess, onError: onError)
    }

    func start(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        updateWorkOrderWithStatus("in_progress", onSuccess: onSuccess, onError: onError)
    }

    func arrive(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        self.pendingArrival = true

        updateWorkOrderWithStatus("arriving", onSuccess: { statusCode, mappingResult in
            self.pendingArrival = false
            onSuccess(statusCode, mappingResult)
        }, onError: { error, statusCode, responseString in
            self.pendingArrival = false
            onError(error, statusCode, responseString)
        })
    }

    func abandon(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        updateWorkOrderWithStatus("abandoned", onSuccess: onSuccess, onError: onError)
    }

    func cancel(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        updateWorkOrderWithStatus("canceled", onSuccess: onSuccess, onError: onError)
    }

    func approve(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        complete(onSuccess: onSuccess, onError: onError)
    }

    func reject(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        updateWorkOrderWithStatus("rejected", onSuccess: onSuccess, onError: onError)
    }

    func complete(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        updateWorkOrderWithStatus("completed", onSuccess: onSuccess, onError: onError)
    }

    func submitForApproval(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        updateWorkOrderWithStatus("pending_approval", onSuccess: onSuccess, onError: onError)
    }

    func updateWorkOrderWithStatus(_ status: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        self.status = status
        ApiService.shared.updateWorkOrderWithId(String(id), params: ["status": status as AnyObject], onSuccess: { statusCode, mappingResult in
            WorkOrderService.shared.updateWorkOrder(self)
            onSuccess(statusCode, mappingResult)
        }, onError: onError)
    }

    func attach( _ image: UIImage, params: [String: AnyObject], onSuccess: @escaping KTApiSuccessHandler, onError: @escaping KTApiFailureHandler) {
        let data = UIImageJPEGRepresentation(image, 1.0)!

        ApiService.shared.addAttachment(data, withMimeType: "image/jpg", toWorkOrderWithId: String(id), params: params, onSuccess: { response in
            if self.attachments == nil {
                self.attachments = [Attachment]()
            }
            self.attachments.append(response?.firstObject as! Attachment)
            onSuccess(response)
        }, onError: onError)
    }

    func addComment(_ comment: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        ApiService.shared.addComment(comment, toWorkOrderWithId: String(id), onSuccess: { statusCode, mappingResult in
            if self.comments == nil {
                self.comments = [Comment]()
            }
            self.comments.insert(mappingResult?.firstObject as! Comment, at: 0)
            onSuccess(statusCode, mappingResult)
        }, onError: onError)
    }

    func reloadComments(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if id > 0 {
            comments = [Comment]()
            ApiService.shared.fetchComments(forWorkOrderWithId: String(id), onSuccess: { statusCode, mappingResult in
                let fetchedComments = (mappingResult?.array() as! [Comment]).reversed()
                for comment in fetchedComments {
                    self.comments.append(comment)
                }
                onSuccess(statusCode, mappingResult)
            }, onError: onError)
        }
    }

    func scoreProvider(_ netPromoterScore: NSNumber, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        providerRating = netPromoterScore
        ApiService.shared.updateWorkOrderWithId(String(id), params: ["provider_rating": providerRating], onSuccess: { statusCode, mappingResult in
            WorkOrderService.shared.updateWorkOrder(self)
            onSuccess(statusCode, mappingResult)
        }, onError: onError)
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
