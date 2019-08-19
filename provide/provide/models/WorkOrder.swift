//
//  WorkOrder.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
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
    var jobId = 0
    var desc: String!
    var workOrderProviders: [WorkOrderProvider]!
    var scheduledStartAt: String!
    var scheduledEndAt: String!
    var startedAt: String!
    var dueAt: String!
    var endedAt: String!
    var canceledAt: String!
    var duration: Double = 0
    var estimatedCost = -1.0
    var estimatedPrice = -1.0
    var estimatedDistance: Double = 0
    var estimatedDuration: Double = 0
    var status: String = "none"
    var previewImage: UIImage!
    var providerRating: Double = 0
    var attachments: [Attachment]!
    var config: [String: Any]!
    var configJson: String!
    var expensesCount = 0
    var expensedAmount: Double!
    var paymentMethods: [PaymentMethod]!
    var price: Double!
    var priority = 0
    var supervisors: [User]!

    func estimatedPriceForCategory(_ categoryId: Int) -> Double? {
        if let estimatesByCategory = config["estimates_by_category"] as? [[String: Double]] {
            for object in estimatesByCategory {
                let categoryId_ = Int(object["category_id"]!)
                let price = object["price"]
                if categoryId == categoryId_ {
                    return price
                }
            }
        }
        return nil
    }

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
            "canceled_at": "canceledAt",
            "duration": "duration",
            "estimated_cost": "estimatedCost",
            "estimated_distance": "estimatedDistance",
            "estimated_duration": "estimatedDuration",
            "estimated_price": "estimatedPrice",
            "status": "status",
            "provider_rating": "providerRating",
            "expenses_count": "expensesCount",
            "expensed_amount": "expensedAmount",
            "payment_methods": "paymentMethods",
            "price": "price",
            "priority": "priority",
            "user_id": "userId",
        ])
        mapping?.addRelationshipMapping(withSourceKeyPath: "user", mapping: User.mapping())
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", with: Attachment.mappingWithRepresentations()))
        mapping?.addRelationshipMapping(withSourceKeyPath: "category", mapping: Category.mapping())
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "payment_methods", toKeyPath: "payment_methods", with: PaymentMethod.mapping()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "supervisors", toKeyPath: "supervisors", with: User.mapping()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "work_order_providers", toKeyPath: "workOrderProviders", with: WorkOrderProvider.mapping()))

        return mapping!
    }

    private var allowNewComments: Bool {
        return status != "none" && status != "awaiting_schedule"
    }

    var annotation: Annotation {
        return Annotation(workOrder: self)
    }

    var annotationPin: Annotation {
        return Annotation(workOrder: self, forcePin: true)
    }

    private var pendingArrival = false

    var canArrive: Bool {
        return !pendingArrival && status == "en_route" && isCurrentUserProvider
    }

    var scheduledStartAtDate: Date? {
        if let scheduledStartAt = scheduledStartAt {
            return Date.fromString(scheduledStartAt)
        }
        return nil
    }

    var nextTimeoutAtDate: Date? {
        if let timeoutAt = config["timeout_at"] as? String {
            return Date.fromString(timeoutAt)
        }
        return nil
    }

    private var dueAtDate: Date? {
        if let dueAt = dueAt {
            return Date.fromString(dueAt)
        }
        return nil
    }

    private var scheduledEndAtDate: Date? {
        if let scheduledEndAt = scheduledEndAt {
            return Date.fromString(scheduledEndAt)
        }
        return nil
    }

    private var scheduledDueDate: Date! {
        return scheduledEndAtDate
    }

    private var startedAtDate: Date? {
        if let startedAt = startedAt {
            return Date.fromString(startedAt)
        }
        return nil
    }

    private var endedAtDate: Date? {
        if let endedAt = endedAt {
            return Date.fromString(endedAt)
        }
        return nil
    }

    private var canceledAtDate: Date? {
        if let canceledAt = canceledAt {
            return Date.fromString(canceledAt)
        }
        return nil
    }

    var humanReadablePrice: String? {
        if let price = price {
            return "$\(NSString(format: "%.02f", price))"
        }
        return "$0.00"
    }

    private var humanReadableEstimatedCost: String? {
        if estimatedCost > -1.0 {
            return "$\(NSString(format: "%.02f", estimatedCost))"
        }
        return nil
    }

    var humanReadableDuration: String? {
        guard let startedAtDate = startedAtDate else { return nil }

        var seconds = 0.0

        var endedAtDate = self.endedAtDate

        if let date = endedAtDate {
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

    var humanReadableDueAtTimestamp: String? {
        if let dueAtDate = dueAtDate {
            if isIPad() {
                return "\(dueAtDate.dayOfWeek), \(dueAtDate.monthName) \(dueAtDate.dayOfMonth) @ \(dueAtDate.timeString!)"
            } else {
                return "\(dueAtDate.month)/\(dueAtDate.dayOfMonth)/\(dueAtDate.year) @ \(dueAtDate.timeString!)"
            }
        }
        return nil
    }

    var humanReadableScheduledStartAtTimestamp: String? {
        guard let scheduledStartAtDate = scheduledStartAtDate else { return nil }

        if isIPad() {
            return "\(scheduledStartAtDate.dayOfWeek), \(scheduledStartAtDate.monthName) \(scheduledStartAtDate.dayOfMonth) @ \(scheduledStartAtDate.timeString!)"
        } else {
            return "\(scheduledStartAtDate.month)/\(scheduledStartAtDate.dayOfMonth)/\(scheduledStartAtDate.year) @ \(scheduledStartAtDate.timeString!)"
        }
    }

    private var humanReadableScheduledEndAtTimestamp: String? {
        guard let scheduledEndAtDate = scheduledEndAtDate else { return nil }

        if isIPad() {
            return "\(scheduledEndAtDate.dayOfWeek), \(scheduledEndAtDate.monthName) \(scheduledEndAtDate.dayOfMonth) @ \(scheduledEndAtDate.timeString!)"
        } else {
            return "\(scheduledEndAtDate.month)/\(scheduledEndAtDate.dayOfMonth)/\(scheduledEndAtDate.year) @ \(scheduledEndAtDate.timeString!)"
        }
    }

    var humanReadableStartedAtTimestamp: String? {
        guard let startedAtDate = startedAtDate else { return nil }
        return "\(startedAtDate.dayOfWeek), \(startedAtDate.monthName) \(startedAtDate.dayOfMonth) @ \(startedAtDate.timeString!)"
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
        } else if status == "pending_approval" {
            return Color.pendingCompletionStatusColor()
        }

        return .clear
    }

    private var contact: Contact! {
        return user.contact
    }

    var coordinate: CLLocationCoordinate2D? {
        if let config = config {
            if status == "in_progress" {
                if let destination = config["destination"] as? [String: Any],
                    let latitude = destination["latitude"] as? Double,
                    let longitude = destination["longitude"] as? Double {

                    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                }
            } else {
                if let currentLocation = config["current_location"] as? [String: Any] {
                    if let latitude = currentLocation["latitude"] as? Double,
                        let longitude = currentLocation["longitude"] as? Double {

                        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    }
                } else if let origin = config["origin"] as? [String: Any] {
                    if let latitude = origin["latitude"] as? Double,
                        let longitude = origin["longitude"] as? Double {

                        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    }
                }
            }
        }

        if let latitude = user?.lastCheckinLatitude, let longitude = user?.lastCheckinLongitude {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        return nil
    }

    var etaCoordinate: CLLocationCoordinate2D? {
        if let config = config {
            if status == "in_progress" || status == "arriving" {
                if let destination = config["destination"] as? [String: Any],
                    let latitude = destination["latitude"] as? Double,
                    let longitude = destination["longitude"] as? Double {

                    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                }
            } else {
                return coordinate
            }
        }

        return nil
    }

    var components: NSMutableArray {
        if let components = config?["components"] as? NSMutableArray {
            return components
        }
        return NSMutableArray()
    }

    var currentComponentIdentifier: String! {
        var componentIdentifier: String!
        for component in components {
            if let componentDict = component as? [String: Any] {
                if let completed = componentDict["completed"] as? Bool {
                    if !completed {
                        componentIdentifier = componentDict["component"] as? String
                        break
                    }
                } else {
                    componentIdentifier = componentDict["component"] as? String
                    break
                }
            }
        }
        return componentIdentifier
    }

    private var imageCount: Int {
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

    private var isCurrentUserProvider: Bool {
        return providers.contains { $0.userId == currentUser.id }
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

    var overview: [String: Any]? {
        return config["overview"] as? [String: Any]
    }

    var overviewBoundingBox: [String: Any]? { //FIXME!!!!
        if let overview = overview {
            if let boundingBox = overview["bounding_box"] as? [String: Any] {
                return boundingBox
            }
        }

        return nil
    }

    var overviewPolyline: OverviewPolyline? {
        if overview != nil {
            return OverviewPolyline(workOrder: self)
        }
        return nil
    }

    var provider: Provider? {  // HACK-- looks for non-timed out providers... this should be done a lot better than this...
        return (workOrderProviders?.first { !$0.isTimedOut })?.provider
    }

    var providers: [Provider] {
        var providers = [Provider]()
        if let workOrderProviders = workOrderProviders {
            for workOrderProvider in workOrderProviders {
                providers.append(workOrderProvider.provider)
            }
        } else {
            workOrderProviders = []
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
        if status == "en_route" {
            if let currentLocation = config["current_location"] as? [String: Any] {
                if let radius = currentLocation["radius"] as? Double {
                    return radius
                }
            } else if let origin = config["origin"] as? [String: Any] {
                if let radius = origin["radius"] as? Double {
                    return radius
                }
            }

            return 40.0  // ~100ft
        } else if status == "in_progress" {
            if let destination = config?["destination"] as? [String: Any], let radius = destination["radius"] as? Double {
                return radius
            }

            return 40.0  // ~100ft
        }

        return 40.0  // ~100ft
    }

    override func toDictionary(_ snakeKeys: Bool = true, includeNils: Bool = false, ignoreKeys: [String] = []) -> [String: Any] {
        var dictionary = super.toDictionary(ignoreKeys: ["job"])
        dictionary.removeValue(forKey: "preview_image")
        dictionary.removeValue(forKey: "id")
        return dictionary
    }

    private func addProvider(_ provider: Provider, flatFee: Double = -1.0, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
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

    private func updateWorkOrderProvider(_ workOrderProvider: WorkOrderProvider, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        guard let provider = workOrderProvider.provider else { return }

        if hasProvider(provider) {
            var index: Int?
            for wop in workOrderProviders {
                if wop.id == workOrderProvider.id || wop.provider.id == workOrderProvider.provider.id {
                    index = workOrderProviders.index { $0.id == wop.id }
                }
            }
            if let index = index {
                workOrderProviders.replaceSubrange(index...index, with: [workOrderProvider])

                if id > 0 {
                    save(onSuccess: onSuccess, onError: onError)
                }
            }
        }
    }

    func mergeAttachment(_ attachment: Attachment) {
        if attachments == nil {
            attachments = []
        }

        var replaced = false
        var index = 0
        for a in attachments {
            if a.id == attachment.id {
                attachments[index] = attachment
                replaced = true
                break
            }
            index += 1
        }

        if !replaced {
            attachments.append(attachment)
        }
    }

    private func removeProvider(_ provider: Provider, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
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
                self.workOrderProviders = []
            }
            var workOrderProviders = [[String: Any]]()
            for workOrderProvider in self.workOrderProviders {
                var wop: [String: Any] = ["provider_id": workOrderProvider.provider.id]
                if workOrderProvider.estimatedDuration > -1.0 {
                    wop["estimated_duration"] = workOrderProvider.estimatedDuration
                }
                if workOrderProvider.hourlyRate > -1.0 {
                    wop["hourly_rate"] = workOrderProvider.hourlyRate
                }
                if workOrderProvider.flatFee > -1.0 {
                    wop["flat_fee"] = workOrderProvider.flatFee
                }
                if workOrderProvider.id > 0 {
                    wop["id"] = workOrderProvider.id
                }
                workOrderProviders.append(wop)
            }

            params["work_order_providers"] = workOrderProviders

            ApiService.shared.updateWorkOrderWithId(String(id), params: params, onSuccess: { statusCode, mappingResult in
                WorkOrderService.shared.updateWorkOrder(self)
                onSuccess(statusCode, mappingResult)
            }, onError: onError)
        } else {
            var workOrderProviders = [[String: Any]]()
            for provider in providers {
                workOrderProviders.append(["provider_id": provider.id])
            }
            params["work_order_providers"] = workOrderProviders

            if scheduledStartAt != nil {
                params["status"] = "scheduled"
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
        reload([
            "include_estimated_cost": "false",
            "include_job": "false",
            "include_supervisors": "false",
            "include_work_order_providers": "true",
            "include_work_order_payment_methods": "true",
        ], onSuccess: onSuccess, onError: onError)
    }

    private func reload(_ params: [String: Any], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if id > 0 {
            ApiService.shared.fetchWorkOrderWithId(String(id), params: params, onSuccess: { [weak self] statusCode, mappingResult in
                let workOrder = mappingResult?.firstObject as! WorkOrder
                self?.config = workOrder.config
                self?.status = workOrder.status
                self?.estimatedCost = workOrder.estimatedCost
                self?.supervisors = workOrder.supervisors
                self?.user = workOrder.user
                self?.userId = workOrder.userId
                self?.workOrderProviders = workOrder.workOrderProviders
                WorkOrderService.shared.updateWorkOrder(mappingResult?.firstObject as! WorkOrder)
                onSuccess(statusCode, mappingResult)
            }, onError: onError)
        }
    }

    func reloadAttachments(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if id > 0 {
            ApiService.shared.fetchAttachments(forWorkOrderWithId: String(id), onSuccess: { statusCode, mappingResult in
                self.attachments = mappingResult?.array() as? [Attachment]
                onSuccess(statusCode, mappingResult)
            }, onError: onError)
        }
    }

    private func hasProvider(_ provider: Provider) -> Bool {
        return providers.contains { $0.id == provider.id }
    }

    private func removeProvider(_ provider: Provider) {
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

    private func hasPaymentMethod(_ paymentMethod: PaymentMethod) -> Bool {
        if paymentMethods == nil {
            return false
        }
        return paymentMethods.contains { $0.id == paymentMethod.id }
    }

    func removePaymentMethod(_ paymentMethod: PaymentMethod) {
        if hasPaymentMethod(paymentMethod) {
            var i = -1
            for pm in paymentMethods {
                i += 1
                if pm.id == paymentMethod.id {
                    break
                }
            }
            paymentMethods.remove(at: i)
        }
    }

    func addPaymentMethod(_ paymentMethod: PaymentMethod) {
        if paymentMethods == nil {
            paymentMethods = [PaymentMethod]()
        }

        if !hasPaymentMethod(paymentMethod) {
//            let workOrderPaymentMethod = WorkOrderPaymentMethod()
//            workOrderPaymentMethod.paymentMethod = paymentMethod
            paymentMethods.append(paymentMethod)
        }
    }

    func setComponents(_ components: NSMutableArray) {
        let mutableConfig = NSMutableDictionary(dictionary: config)
        mutableConfig.setObject(components, forKey: "components" as NSCopying)
        config = mutableConfig as? [String: Any]
    }

    func route(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        updateWorkOrderWithStatus("en_route", onSuccess: onSuccess, onError: onError)
    }

    func start(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        updateWorkOrderWithStatus("in_progress", onSuccess: onSuccess, onError: onError)
    }

    func arrive(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        pendingArrival = true

        updateWorkOrderWithStatus("arriving", onSuccess: { statusCode, mappingResult in
            self.pendingArrival = false
            onSuccess(statusCode, mappingResult)
        }, onError: { error, statusCode, responseString in
            self.pendingArrival = false
            onError(error, statusCode, responseString)
        })
    }

    private func cancel(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        updateWorkOrderWithStatus("canceled", onSuccess: onSuccess, onError: onError)
    }

    private func approve(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        complete(onSuccess: onSuccess, onError: onError)
    }

    func complete(onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        updateWorkOrderWithStatus("completed", onSuccess: onSuccess, onError: onError)
    }

    func updateWorkOrderWithStatus(_ status: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        self.status = status
        ApiService.shared.updateWorkOrderWithId(String(id), params: ["status": status], onSuccess: { statusCode, mappingResult in
            WorkOrderService.shared.updateWorkOrder(self)
            onSuccess(statusCode, mappingResult)
        }, onError: onError)
    }

    class Annotation: NSObject, MKAnnotation {
        var workOrder: WorkOrder!

        private(set) var forcePin = false

        required init(workOrder: WorkOrder, forcePin: Bool = false) {
            self.workOrder = workOrder
            self.forcePin = forcePin
        }

        @objc var coordinate: CLLocationCoordinate2D {
            return workOrder.coordinate!
        }

        // Title and subtitle for use by selection UI.
        @objc var title: String? {
            return nil //workOrder.title
        }

        @objc var subtitle: String? {
            return nil //workOrder.subtitle
        }

        func matches(_ otherWorkOrder: WorkOrder) -> Bool {
            return otherWorkOrder.id == workOrder.id
        }
    }

    class OverviewPolyline: MKPolyline {
        var workOrder: WorkOrder!

        required convenience init(workOrder: WorkOrder) {
            var coords = [CLLocationCoordinate2D]()
            if let overview = workOrder.overview {
                if workOrder.isCurrentUserProvider {
                    logWarn("Not yet showing provider to trip origin part of polyline")
                }
                if let shape = overview["shape"] as? [String] {
                    for shpe in shape {
                        let shapeCoords = shpe.components(separatedBy: ",")
                        let latitude = shapeCoords.count > 0 ? (shapeCoords.first! as NSString).doubleValue : 0.0
                        let longitude = shapeCoords.count > 1 ? (shapeCoords.last! as NSString).doubleValue : 0.0
                        coords.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                    }
                }
            }

            self.init(coordinates: &coords, count: coords.count)
            self.workOrder = workOrder
        }

        func matches(_ other: OverviewPolyline) -> Bool {
            return other.workOrder.id == workOrder.id
        }
    }
}
