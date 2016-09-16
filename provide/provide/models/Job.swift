//
//  Job.swift
//  provide
//
//  Created by Kyle Thomas on 10/24/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import RestKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class Job: Model {

    var id = 0
    var name: String!
    var companyId = 0
    var company: Company!
    var customerId = 0
    var customer: Customer!
    var comments: [Comment]!
    var contractRevenue = -1.0
    var cost = -1.0
    var attachments: [Attachment]!
    var floorplans: [Floorplan]!
    var status: String!
    var expenses: [Expense]!
    var expensesCount = 0
    var expensedAmount = -1.0
    var laborCost = -1.0
    var laborCostPerSqFt = 0.0
    var laborCostPercentageOfRevenue = -1.0
    var materialsCost = -1.0
    var materialsCostPerSqFt = -1.0
    var materialsCostPercentageOfRevenue = -1.0
    var materials: [JobProduct]!
    var profit = -1.0
    var profitMargin = -1.0
    var profitPerSqFt = -1.0
    var quotedPricePerSqFt = -1.0
    var supervisors: [Provider]!
    var type: String!
    var thumbnailImageUrlString: String!
    var totalSqFt = -1.0
    var workOrdersCount = 0
//    var workOrders: [WorkOrder]!
    var wizardMode: NSNumber!
    var tasks: [Task]!

    var workOrders: [WorkOrder]! {
        var workOrders: [WorkOrder]!
        if let floorplans = floorplans {
            workOrders = [WorkOrder]()
            for floorplan in floorplans {
                if let floorplanWorkOrders = floorplan.workOrders {
                    for workOrder in floorplanWorkOrders {
                        workOrders.append(workOrder)
                    }
                }
            }
        }
        return workOrders
    }

    var thumbnailImageUrl: URL! {
        if let thumbnailImageUrlString = thumbnailImageUrlString {
            return URL(string: thumbnailImageUrlString)
        }
        return nil
    }

    var isWizardMode: Bool {
        if let wizardMode = wizardMode {
            return wizardMode.boolValue
        }
        return false
    }

    var isEditMode: Bool {
        let hasFloorplan = floorplans?.count > 0
        let hasScale = hasFloorplan && floorplans?.first!.scale != nil
        let hasSupervisor = supervisors?.count > 0
        let hasInventory = materials?.count > 0
        let hasWorkOrders = workOrdersCount > 0
        return !isWizardMode && ((hasFloorplan && hasScale && hasSupervisor && hasInventory && hasWorkOrders) || status != "configuring")
    }

    var isReviewMode: Bool {
        if let status = status {
            return ["pending_completion", "completed"].index(of: status) != nil
        }
        return false
    }

    var canTransitionToInProgressStatus: Bool {
        if let status = status {
            return status == "configuring"
        }
        return false
    }

    var canTransitionToReviewAndCompleteStatus: Bool {
        if let status = status {
            if let _ = ["in_progress"].index(of: status) {
                if let tasks = tasks {
                    for task in tasks {
                        if task.completedAt == nil {
                            return false
                        }
                    }
                }

                if let workOrders = workOrders {
                    for workOrder in workOrders {
                        if !workOrder.isCompleted {
                            return false
                        }
                    }
                }

                return true
            }
        }
        return false
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(for: self)
        mapping?.addAttributeMappings(from: [
            "id": "id",
            "name": "name",
            "company_id": "companyId",
            "customer_id": "customerId",
            "contract_revenue": "contractRevenue",
            "status": "status",
            "quoted_price_per_sq_ft": "quotedPricePerSqFt",
            "total_sq_ft": "totalSqFt",
            "work_orders_count": "workOrdersCount",
            "wizard_mode": "wizardMode",
            "cost": "cost",
            "labor_cost": "laborCost",
            "labor_cost_per_sq_ft": "laborCostPerSqFt",
            "labor_cost_percentage_of_revenue": "laborCostPercentageOfRevenue",
            "materials_cost": "materialsCost",
            "materials_cost_per_sq_ft": "materialsCostPerSqFt",
            "materials_cost_percentage_of_revenue": "materialsCostPercentageOfRevenue",
            "profit": "profit",
            "profit_margin": "profitMargin",
            "profit_per_sq_ft": "profitPerSqFt",
            "type": "type",
            "thumbnail_image_url": "thumbnailImageUrlString",
            ])
        mapping?.addRelationshipMapping(withSourceKeyPath: "company", mapping: Company.mapping())
        mapping?.addRelationshipMapping(withSourceKeyPath: "customer", mapping: Customer.mapping())
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", with: Attachment.mappingWithRepresentations()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "comments", toKeyPath: "comments", with: Comment.mapping()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "expenses", toKeyPath: "expenses", with: Expense.mapping()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "floorplans", toKeyPath: "floorplans", with: Floorplan.mapping()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "materials", toKeyPath: "materials", with: JobProduct.mapping()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "supervisors", toKeyPath: "supervisors", with: Provider.mapping()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "tasks", toKeyPath: "tasks", with: Task.mapping()))
        return mapping!
    }

    var annotation: Annotation {
        return Annotation(job: self)
    }

    var isCommercial: Bool {
        if let type = type {
            return type == "commercial"
        }
        return false
    }

    var isPunchlist: Bool {
        if let type = type {
            return type == "punchlist"
        }
        return false
    }

    var isResidential: Bool {
        if let type = type {
            return type == "residential"
        }
        return false
    }

    var isCurrentUserCompanyAdmin: Bool {
        let user = currentUser()
        for companyId in user.companyIds {
            if self.companyId == companyId {
                return true
            }
        }
        return false
    }

    var isCurrentUserSupervisor: Bool {
        if supervisors == nil {
            return false
        }

        let user = currentUser()
        for supervisor in supervisors {
            if supervisor.userId == user.id {
                return true
            }
        }
        return false
    }

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(customer.contact.latitude.doubleValue,
                                          customer.contact.longitude.doubleValue)
    }

    var statusColor: UIColor {
        if status == "configuring" {
            return Color.awaitingScheduleStatusColor()
        } else if status == "scheduled" {
            return Color.scheduledStatusColor()
        } else if status == "canceled" {
            return Color.canceledStatusColor()
        } else if status == "completed" {
            return Color.completedStatusColor()
        }

        return UIColor.clear
    }

    var humanReadableContractRevenue: String! {
        if contractRevenue > -1.0 {
            return "$\(NSString(format: "%.02f", contractRevenue))"
        }
        return nil
    }

    var humanReadableCost: String! {
        if cost > -1.0 {
            return "$\(NSString(format: "%.02f", cost))"
        }
        return nil
    }

    var humanReadableProfit: String! {
        if profit > -1.0 {
            return "$\(NSString(format: "%.02f", profit))"
        }
        return nil
    }

    var humanReadableProfitMargin: String! {
        if profitMargin > -1.0 {
            return "\(NSString(format: "%.0f", profitMargin * 100.0))%"
        }
        return nil
    }

    var humanReadableProfitPerSqFt: String! {
        if profitPerSqFt > -1.0 {
            return "$\(NSString(format: "%.02f", profitPerSqFt))"
        }
        return nil
    }

    var humanReadableExpenses: String! {
        if expensedAmount > -1.0 {
            return "$\(NSString(format: "%.02f", expensedAmount))"
        }
        return nil
    }

    var humanReadableLaborCost: String! {
        if laborCost > -1.0 {
            return "$\(NSString(format: "%.02f", laborCost))"
        }
        return nil
    }

    var humanReadableLaborCostPerSqFt: String! {
        if laborCostPerSqFt > -1.0 {
            return "$\(NSString(format: "%.02f", laborCostPerSqFt))"
        }
        return nil
    }

    var humanReadableLaborCostPercentageOfRevenue: String! {
        if laborCostPercentageOfRevenue > -1.0 {
            return "\(NSString(format: "%.0f", laborCostPercentageOfRevenue * 100.0))%"
        }
        return nil
    }

    var humanReadableMaterialsCost: String! {
        if materialsCost > -1.0 {
            return "$\(NSString(format: "%.02f", materialsCost))"
        }
        return nil
    }

    var humanReadableMaterialsCostPerSqFt: String! {
        if materialsCostPerSqFt > -1.0 {
            return "$\(NSString(format: "%.02f", materialsCostPerSqFt))"
        }
        return nil
    }

    var humanReadableMaterialsCostPercentageOfRevenue: String! {
        if materialsCostPercentageOfRevenue > -1.0 {
            return "\(NSString(format: "%.0f", materialsCostPercentageOfRevenue * 100.0))%"
        }
        return nil
    }

    func hasSupervisor(_ supervisor: Provider) -> Bool {
        if let supervisors = supervisors {
            for s in supervisors {
                if s.id == supervisor.id {
                    return true
                }
            }
        }
        return false
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

    func prependExpense(_ expense: Expense) {
        if expenses == nil {
            expenses = [Expense]()

            if expensedAmount == -1.0 {
                expensedAmount = 0.0
            }
        }

        expenses.insert(expense, at: 0)

        expensesCount += 1
        expensedAmount = expensedAmount + expense.amount
    }

    func addComment(_ comment: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        ApiService.sharedService().addComment(comment, toJobWithId: String(id),
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
            ApiService.sharedService().fetchComments(forJobWithId: String(id),
                onSuccess: { statusCode, mappingResult in
                    if self.comments == nil {
                        self.comments = [Comment]()
                    }
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

    func reloadFinancials(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if id > 0 {
            let params: [String : AnyObject] = [
                "include_expenses": "false" as AnyObject,
                "include_products": "false" as AnyObject,
                "include_supervisors": "true" as AnyObject,
            ]

            reload(params,
                onSuccess: { statusCode, mappingResult in
                    let job = mappingResult?.firstObject as! Job

                    self.supervisors = job.supervisors

                    self.contractRevenue = job.contractRevenue
                    self.cost = job.cost

                    self.expenses = job.expenses
                    self.expensesCount = job.expensesCount
                    self.expensedAmount = job.expensedAmount

                    self.materials = job.materials
                    self.materialsCost = job.materialsCost
                    self.materialsCostPercentageOfRevenue = job.materialsCostPercentageOfRevenue
                    self.materialsCostPerSqFt = job.materialsCostPerSqFt

                    self.laborCost = job.laborCost
                    self.laborCostPercentageOfRevenue = job.laborCostPercentageOfRevenue
                    self.laborCostPerSqFt = job.laborCostPerSqFt

                    self.profit = job.profit
                    self.profitPerSqFt = job.profitPerSqFt
                    self.profitMargin = job.profitMargin

                    onSuccess(statusCode, mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error, statusCode, responseString)
                }
            )
        }
    }

    func reloadFloorplans(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if id > 0 {
            ApiService.sharedService().fetchFloorplans(forJobWithId: String(id), params: [:],
                onSuccess: { statusCode, mappingResult in
                    if self.floorplans == nil {
                        self.floorplans = [Floorplan]()
                    }

                    let fetchedFloorplans = mappingResult?.array() as! [Floorplan]
                    for floorplan in fetchedFloorplans {
                        self.floorplans.append(floorplan)
                    }

                    onSuccess(statusCode, mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error, statusCode, responseString)
                }
            )
        }
    }

    func reloadExpenses(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if id > 0 {
            ApiService.sharedService().fetchExpenses(forJobWithId: String(id),
                onSuccess: { statusCode, mappingResult in
                    self.expenses = mappingResult?.array() as! [Expense]
                    self.expensesCount = self.expenses.count
                    self.expensedAmount = 0.0
                    for expense in self.expenses {
                        self.expensedAmount = self.expensedAmount + expense.amount
                    }
                    onSuccess(statusCode, mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error, statusCode, responseString)
                }
            )
        }
    }

    func addExpense(_ params: [String: AnyObject], receipt: UIImage!, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        ApiService.sharedService().createExpense(params, forExpensableType: "job",
            withExpensableId: String(self.id), onSuccess: { statusCode, mappingResult in
                let expenseStatusCode = statusCode
                let expenseMappingResult = mappingResult
                let expense = mappingResult?.firstObject as! Expense

                self.prependExpense(expense)

                if let receipt = receipt {
                    expense.attach(receipt, params: params,
                        onSuccess: { (statusCode, mappingResult) -> () in
                            onSuccess(expenseStatusCode, expenseMappingResult)
                        },
                        onError: { (error, statusCode, responseString) -> () in
                            onError(error, statusCode, responseString)
                        }
                    )
                } else {
                    onSuccess(statusCode, mappingResult)
                }
            },
            onError: { error, statusCode, responseString in
                onError(error, statusCode, responseString)
            }
        )
    }

    func addSupervisor(_ supervisor: Provider, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if !hasSupervisor(supervisor) {
            supervisors.append(supervisor)
            save(onSuccess, onError: onError)
        }
    }
    
    func removeSupervisor(_ supervisor: Provider, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if hasSupervisor(supervisor) {
            var i = -1
            for s in supervisors {
                i += 1
                if s.id == supervisor.id {
                    break
                }
            }
            supervisors.remove(at: i)
            save(onSuccess, onError: onError)
        }
    }

    func reloadMaterials(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if id > 0 {
            let params: [String : AnyObject] = ["include_products": "true" as AnyObject]
            ApiService.sharedService().fetchJobWithId(String(id), params: params,
                onSuccess: { statusCode, mappingResult in
                    self.materials = (mappingResult?.firstObject as! Job).materials
                    onSuccess(statusCode, mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error, statusCode, responseString)
                }
            )
        }
    }

    func jobProductForProduct(_ product: Product) -> JobProduct! {
        if let materials = materials {
            for jobProduct in materials {
                if jobProduct.productId == product.id {
                    return jobProduct
                }
            }
        }
        return nil
    }

    func addJobProductForProduct(_ product: Product, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if jobProductForProduct(product) == nil && materials != nil {
            let jobProduct = JobProduct()
            jobProduct.jobId = id
            jobProduct.productId = product.id

            if let initialQuantity = params["initial_quantity"] as? Double {
                jobProduct.initialQuantity = initialQuantity
            }

            if let price = params["price"] as? Double {
                jobProduct.price = price
            }

            materials.append(jobProduct)

            save({ statusCode, mappingResult in
                    let saveMappingResult = mappingResult
                    self.reloadMaterials(
                        { statusCode, mappingResult in
                            onSuccess(statusCode, saveMappingResult)
                        },
                        onError: { error, statusCode, responseString in
                            onError(error, statusCode, responseString)
                        }
                    )
                },
                onError: { error, statusCode, responseString in
                    onError(error, statusCode, responseString)
                }
            )
        }
    }

    func removeJobProductForProduct(_ product: Product, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if let jobProduct = jobProductForProduct(product) {
            removeJobProduct(jobProduct, onSuccess: onSuccess, onError: onError)
        }
    }

    func removeJobProduct(_ jobProduct: JobProduct, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        materials.removeObject(jobProduct)
        save(onSuccess, onError: onError)
    }

    func reloadSupervisors(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if id > 0 {
            let params: [String : AnyObject] = ["include_supervisors": "true" as AnyObject]
            ApiService.sharedService().fetchJobWithId(String(id), params: params,
                onSuccess: { statusCode, mappingResult in
                    self.supervisors = (mappingResult?.firstObject as! Job).supervisors
                    onSuccess(statusCode, mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error, statusCode, responseString)
                }
            )
        }
    }

    func reload(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        reload([String : AnyObject](), onSuccess: onSuccess, onError: onError)
    }

    func reload(_ params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        ApiService.sharedService().fetchJobWithId(String(id), params: params,
            onSuccess: { statusCode, mappingResult in
                let job = mappingResult?.firstObject as! Job

                if let floorplans = job.floorplans {
                    self.floorplans = floorplans
                }

                if let materials = job.materials {
                    self.materials = materials
                }

                if let supervisors = job.supervisors {
                    self.supervisors = supervisors
                }

                self.thumbnailImageUrlString = job.thumbnailImageUrlString

                // TODO-- marshall the rest of the fields

                JobService.sharedService().updateJob(job)

                onSuccess(statusCode, mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error, statusCode, responseString)
            }
        )
    }

    func cancel(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        ApiService.sharedService().updateJobWithId(String(id), params: ["status": "canceled" as AnyObject],
            onSuccess: { statusCode, mappingResult in
                self.status = "canceled"
                onSuccess(statusCode, mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error, statusCode, responseString)
            }
        )
    }

    func save(_ onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        var params = toDictionary()
        params.removeValue(forKey: "id")

        if id > 0 {
            if let floorplans = floorplans {
                var floorplanIds = [Int]()
                for floorplan in floorplans {
                    floorplanIds.append(floorplan.id)
                }
                params.updateValue(floorplanIds as AnyObject, forKey: "floorplan_ids")
            }

            if let materials = materials {
                var jobProducts = [[String : AnyObject]]()
                for jobProduct in materials {
                    var jp: [String : AnyObject] = ["job_id": id as AnyObject, "product_id": jobProduct.productId as AnyObject, "initial_quantity": jobProduct.initialQuantity as AnyObject]
                    if jobProduct.price > -1.0 {
                        jp.updateValue(jobProduct.price as AnyObject, forKey: "price")
                    }
                    if jobProduct.id > 0 {
                        jp.updateValue(jobProduct.id as AnyObject, forKey: "id")
                    }
                    jobProducts.append(jp)
                }
                params.updateValue(jobProducts as AnyObject, forKey: "materials")
            }

            ApiService.sharedService().updateJobWithId(String(id), params: params,
                onSuccess: { statusCode, mappingResult in
                    onSuccess(statusCode, mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error, statusCode, responseString)
                }
            )
        } else {
            ApiService.sharedService().createJob(params,
                onSuccess: { statusCode, mappingResult in
                    let job = mappingResult?.firstObject as! Job
                    self.id = job.id
                    self.status = job.status
                    onSuccess(statusCode, mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error, statusCode, responseString)
                }
            )
        }
    }

    func updateJobFloorplanScale(_ floorplanScale: CGFloat, onSuccess: OnSuccess, onError: OnError) {
//        if let floorplan = floorplan {
//            self.floorplanScale = Double(floorplanScale)
//
//            var metadata = floorplan.metadata.mutableCopy() as! [String : AnyObject]
//            metadata["scale"] = floorplanScale
//            floorplan.updateAttachment(["metadata": metadata], onSuccess: onSuccess, onError: onError)
//        }
    }

    func updateJobWithStatus(_ status: String, onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        self.status = status
        ApiService.sharedService().updateJobWithId(String(id), params: ["status": status as AnyObject],
            onSuccess: { statusCode, mappingResult in
                JobService.sharedService().updateJob(self)
                onSuccess(statusCode, mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error, statusCode, responseString)
            }
        )
    }

    class Annotation: NSObject, MKAnnotation {
        fileprivate var job: Job!

        required init(job: Job) {
            self.job = job
        }

        @objc var coordinate: CLLocationCoordinate2D {
            return job.coordinate
        }

        @objc var title: String? {
            return job.name
        }

        @objc var subtitle: String? {
            return nil
        }
    }
}
