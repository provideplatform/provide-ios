//
//  Job.swift
//  provide
//
//  Created by Kyle Thomas on 10/24/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class Job: Model {

    var id = 0
    var name: String!
    var companyId = 0
    var company: Company!
    var customerId = 0
    var customer: Customer!
    var comments: [Comment]!
    var contractRevenue: NSNumber!
    var cost: NSNumber!
    var attachments: [Attachment]!
    var blueprints: [Attachment]!
    var blueprintImageUrlString: String!
    var blueprintScale = 0.0
    var blueprintAnnotationsCount = 0
    var status: String!
    var estimates: [Estimate]!
    var estimatesCount = 0
    var estimatedAmount: NSNumber!
    var expenses: [Expense]!
    var expensesCount = 0
    var expensedAmount: NSNumber!
    var laborCost: NSNumber!
    var laborCostPerSqFt: NSNumber!
    var laborCostPercentageOfRevenue: NSNumber!
    var materialsCost: NSNumber!
    var materialsCostPerSqFt: NSNumber!
    var materialsCostPercentageOfRevenue: NSNumber!
    var materials: [JobProduct]!
    var profit: NSNumber!
    var profitMargin: NSNumber!
    var profitPerSqFt: NSNumber!
    var quotedPricePerSqFt: NSNumber!
    var supervisors: [Provider]!
    var type: String!
    var totalSqFt: NSNumber!
    var workOrdersCount = 0
    var workOrders: [WorkOrder]!
    var wizardMode: NSNumber!
    var tasks: [Task]!

    var isWizardMode: Bool {
        if let wizardMode = wizardMode {
            return wizardMode.boolValue
        }
        return false
    }

    var isEditMode: Bool {
        let hasBlueprint = (blueprints?.count)! > 0
        let hasScale = hasBlueprint && blueprints?.first!.metadata["scale"] != nil
        let hasSupervisor = (supervisors?.count)! > 0
        let hasInventory = (materials?.count)! > 0
        let hasWorkOrders = workOrdersCount > 0
        return !isWizardMode && ((hasBlueprint && hasScale && hasSupervisor && hasInventory && hasWorkOrders) || status != "configuring")
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
            "blueprint_image_url": "blueprintImageUrlString",
            "blueprint_scale": "blueprintScale",
            "blueprint_annotations_count": "blueprintAnnotationsCount",
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
            ])
        mapping?.addRelationshipMapping(withSourceKeyPath: "company", mapping: Company.mapping())
        mapping?.addRelationshipMapping(withSourceKeyPath: "customer", mapping: Customer.mapping())
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", withMapping: Attachment.mapping()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "blueprints", toKeyPath: "blueprints", withMapping: Attachment.mapping()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "comments", toKeyPath: "comments", withMapping: Comment.mapping()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "expenses", toKeyPath: "expenses", withMapping: addExpense.mapping()))
//        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "floorplans", toKeyPath: "floorplans", withMapping: Floorplan.mapping()))
//        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "floorplan_jobs", toKeyPath: "floorplanJobs", withMapping: FloorplanJob.mapping()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "materials", toKeyPath: "materials", withMapping: JobProduct.mapping()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "supervisors", toKeyPath: "supervisors", withMapping: Provider.mapping()))
        mapping?.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "tasks", toKeyPath: "tasks", withMapping: Task.mapping()))
        return mapping!
    }

    var annotation: Annotation {
        return Annotation(job: self)
    }

    var blueprintImageUrl: NSURL! {
        if let blueprintImageUrlString = blueprintImageUrlString {
            return NSURL(string: blueprintImageUrlString)
        }
        return nil
    }

    var hasPendingBlueprint: Bool {
        if let blueprint = blueprint {
            return blueprint.status == "pending"
        }
        return false
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
        let user = currentUser
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

        let user = currentUser
        for supervisor in supervisors {
            if supervisor.userId == user?.id {
                return true
            }
        }
        return false
    }

    weak var blueprint: Attachment! {
        if let blueprints = blueprints {
            if blueprints.count > 0 {
                for blueprint in blueprints {
                    if blueprint.mimeType == "image/png" {
                        return blueprint
                    }
                }
            }
        }
        return nil
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
        if contractRevenue != nil {
            return "$\(NSString(format: "%.02f", contractRevenue.doubleValue))"
        }
        return nil
    }

    var humanReadableCost: String! {
        if cost != nil {
            return "$\(NSString(format: "%.02f", cost.doubleValue))"
        }
        return nil
    }

    var humanReadableProfit: String! {
        if let profit = profit {
            return "$\(NSString(format: "%.02f", profit.doubleValue))"
        }
        return nil
    }

    var humanReadableProfitMargin: String! {
        if let profitMargin = profitMargin {
            return "\(NSString(format: "%.0f", profitMargin.doubleValue * 100.0))%"
        }
        return nil
    }

    var humanReadableProfitPerSqFt: String! {
        if let profitPerSqFt = profitPerSqFt {
            return "$\(NSString(format: "%.02f", profitPerSqFt.doubleValue))"
        }
        return nil
    }

    var humanReadableExpenses: String! {
        if expensedAmount != nil {
            return "$\(NSString(format: "%.02f", expensedAmount.doubleValue))"
        }
        return nil
    }

    var humanReadableLaborCost: String! {
        if laborCost != nil {
            return "$\(NSString(format: "%.02f", laborCost.doubleValue))"
        }
        return nil
    }

    var humanReadableLaborCostPerSqFt: String! {
        if laborCostPerSqFt != nil {
            return "$\(NSString(format: "%.02f", laborCostPerSqFt.doubleValue))"
        }
        return nil
    }

    var humanReadableLaborCostPercentageOfRevenue: String! {
        if laborCostPercentageOfRevenue != nil {
            return "\(NSString(format: "%.0f", laborCostPercentageOfRevenue.doubleValue * 100.0))%"
        }
        return nil
    }

    var humanReadableMaterialsCost: String! {
        if materialsCost != nil {
            return "$\(NSString(format: "%.02f", materialsCost.doubleValue))"
        }
        return nil
    }

    var humanReadableMaterialsCostPerSqFt: String! {
        if materialsCostPerSqFt != nil {
            return "$\(NSString(format: "%.02f", materialsCostPerSqFt.doubleValue))"
        }
        return nil
    }

    var humanReadableMaterialsCostPercentageOfRevenue: String! {
        if materialsCostPercentageOfRevenue != nil {
            return "\(NSString(format: "%.0f", materialsCostPercentageOfRevenue.doubleValue * 100.0))%"
        }
        return nil
    }

    func hasSupervisor(supervisor: Provider) -> Bool {
        if let supervisors = supervisors {
            for s in supervisors {
                if s.id == supervisor.id {
                    return true
                }
            }
        }
        return false
    }

    func prependEstimate(estimate: Estimate) {
        if estimates == nil {
            estimates = [Estimate]()

            if estimatedAmount == nil {
                estimatedAmount = 0.0
            }
        }

        estimates.insert(estimate, at: 0)

        estimatesCount += 1
        if let amount = estimate.amount {
            estimatedAmount = estimatedAmount.doubleValue + amount as NSNumber
        }
    }

    func prependExpense(expense: Expense) {
        if expenses == nil {
            expenses = [Expense]()

            if expensedAmount == nil {
                expensedAmount = 0.0
            }
        }

        expenses.insert(expense, at: 0)

        expensesCount += 1
        expensedAmount = expensedAmount.doubleValue + expense.amount as NSNumber
    }

    func addComment(comment: String, onSuccess: OnSuccess, onError: OnError) {
        ApiService.shared.addComment(comment, toJobWithId: String(id),
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
            ApiService.shared.fetchComments(forJobWithId: String(id),
                onSuccess: { statusCode, mappingResult in
                    if self.comments == nil {
                        self.comments = [Comment]()
                    }
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

    func reloadFinancials(onSuccess: OnSuccess, onError: OnError) {
        if id > 0 {
            let params: [String : AnyObject] = [
                "include_expenses": "true" as AnyObject,
                "include_products": "true" as AnyObject,
                "include_supervisors": "true" as AnyObject,
            ]

            reload(params: params,
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

    func reloadEstimates(onSuccess: OnSuccess, onError: OnError) {
        if id > 0 {
            ApiService.shared.fetchEstimates(forJobWithId: String(id),
                onSuccess: { statusCode, mappingResult in
                    self.estimates = mappingResult.array() as! [Estimate]
                    self.estimatesCount = self.estimates.count
                    self.estimatedAmount = 0.0
                    for estimate in self.estimates {
                        if let amount = estimate.amount {
                            self.estimatedAmount = self.estimatedAmount.doubleValue + amount
                        }
                    }
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        }
    }

    func addEstimate(params: [String: AnyObject], forBlueprint blueprint: Attachment!, onSuccess: OnSuccess, onError: OnError) {
        ApiService.shared.createEstimate(params, forJobWithId: String(self.id),
            onSuccess: { statusCode, mappingResult in
                let estimateStatusCode = statusCode
                let estimateMappingResult = mappingResult
                let estimate = mappingResult.firstObject as! Estimate

                self.prependEstimate(estimate)

                if let blueprint = blueprint {
                    let blueprintParams = ["metadata": blueprint.metadata, "description": blueprint.desc, "tags": blueprint.tags]
                    ApiService.shared.addAttachmentFromSourceUrl(blueprint.url, toEstimateWithId: String(estimate.id),
                        forJobWithId: String(self.id), params: blueprintParams, onSuccess: { statusCode, mappingResult in
                            onSuccess(statusCode: estimateStatusCode, mappingResult: estimateMappingResult)
                        },
                        onError: { error, statusCode, responseString in
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

    func reloadExpenses(onSuccess: OnSuccess, onError: OnError) {
        if id > 0 {
            ApiService.shared.fetchExpenses(forJobWithId: String(id),
                onSuccess: { statusCode, mappingResult in
                    self.expenses = mappingResult.array() as! [Expense]
                    self.expensesCount = self.expenses.count
                    self.expensedAmount = 0.0
                    for expense in self.expenses {
                        self.expensedAmount = self.expensedAmount.doubleValue + expense.amount
                    }
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        }
    }

    func addExpense(params: [String: AnyObject], receipt: UIImage!, onSuccess: OnSuccess, onError: OnError) {
        ApiService.shared.createExpense(params, forExpensableType: "job",
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

    func addSupervisor(supervisor: Provider, onSuccess: OnSuccess, onError: OnError) {
        if !hasSupervisor(supervisor: supervisor) {
            supervisors.append(supervisor)
            save(onSuccess: onSuccess, onError: onError)
        }
    }
    
    func removeSupervisor(supervisor: Provider, onSuccess: OnSuccess, onError: OnError) {
        if hasSupervisor(supervisor: supervisor) {
            var i = -1
            for s in supervisors {
                i++
                if s.id == supervisor.id {
                    break
                }
            }
            supervisors.removeAtIndex(i)
            save(onSuccess: onSuccess, onError: onError)
        }
    }

    func reloadMaterials(onSuccess: OnSuccess, onError: OnError) {
        if id > 0 {
            let params: [String : AnyObject] = ["include_products": "true" as AnyObject]
            ApiService.shared.fetchJobWithId(String(id), params: params,
                onSuccess: { statusCode, mappingResult in
                    self.materials = (mappingResult.firstObject as! Job).materials
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        }
    }

    func jobProductForProduct(product: Product) -> JobProduct! {
        if let materials = materials {
            for jobProduct in materials {
                if jobProduct.productId == product.id {
                    return jobProduct
                }
            }
        }
        return nil
    }

    func addJobProductForProduct(product: Product, params: [String : AnyObject], onSuccess: @escaping OnSuccess, onError: @escaping OnError) {
        if jobProductForProduct(product: product) == nil && materials != nil {
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

            save(onSuccess:
                { statusCode, mappingResult in
                    let saveMappingResult = mappingResult
                    self.reloadMaterials(
                        onSuccess: { statusCode, mappingResult in
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

    func removeJobProductForProduct(product: Product, onSuccess: OnSuccess, onError: OnError) {
        if let jobProduct = jobProductForProduct(product: product) {
            removeJobProduct(jobProduct: jobProduct, onSuccess: onSuccess, onError: onError)
        }
    }

    func removeJobProduct(jobProduct: JobProduct, onSuccess: OnSuccess, onError: OnError) {
        materials.removeObject(jobProduct)
        save(onSuccess: onSuccess, onError: onError)
    }

    func reloadSupervisors(onSuccess: OnSuccess, onError: OnError) {
        if id > 0 {
            let params: [String : AnyObject] = ["include_supervisors": "true" as AnyObject]
            ApiService.shared.fetchJobWithId(String(id), params: params,
                onSuccess: { statusCode, mappingResult in
                    self.supervisors = (mappingResult.firstObject as! Job).supervisors
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        }
    }

    func reload(onSuccess: OnSuccess, onError: OnError) {
        reload(params: [String : AnyObject](), onSuccess: onSuccess, onError: onError)
    }

    func reload(params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) {
        ApiService.shared.fetchJobWithId(String(id), params: params,
            onSuccess: { statusCode, mappingResult in
                let job = mappingResult.firstObject as! Job
                self.blueprints = job.blueprints
                self.blueprintImageUrlString = job.blueprintImageUrlString

                if let floorplans = job.floorplans {
                    self.floorplans = floorplans
                }

                if let floorplanJobs = job.floorplanJobs {
                    self.floorplanJobs = floorplanJobs
                }

                if let materials = job.materials {
                    self.materials = materials
                }

                if let supervisors = job.supervisors {
                    self.supervisors = supervisors
                }
                // TODO-- marshall the rest of the fields

                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func cancel(onSuccess: OnSuccess, onError: OnError) {
        ApiService.shared.updateJobWithId(String(id), params: ["status": "canceled"],
            onSuccess: { statusCode, mappingResult in
                self.status = "canceled"
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func save(onSuccess: OnSuccess, onError: OnError) {
        var params = toDictionary()
        params.removeValue(forKey: "id")

        if id > 0 {
            if let floorplans = floorplans {
                var floorplanIds = [Int]()
                for floorplan in floorplans {
                    floorplanIds.append(floorplan.id)
                }
                params.updateValue(floorplanIds, forKey: "floorplan_ids")
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
                params.updateValue(jobProducts, forKey: "materials")
            }

            ApiService.shared.updateJobWithId(String(id), params: params,
                onSuccess: { statusCode, mappingResult in
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        } else {
            ApiService.shared.createJob(params,
                onSuccess: { statusCode, mappingResult in
                    let job = mappingResult.firstObject as! Job
                    self.id = job.id
                    self.status = job.status
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        }
    }

    func updateJobBlueprintScale(blueprintScale: CGFloat, onSuccess: OnSuccess, onError: OnError) {
        if let blueprint = blueprint {
            self.blueprintScale = Double(blueprintScale)

            var metadata = blueprint.metadata.mutableCopy() as! [String : AnyObject]
            metadata["scale"] = blueprintScale
            blueprint.updateAttachment(["metadata": metadata], onSuccess: onSuccess, onError: onError)
        }
    }

    func updateJobWithStatus(status: String, onSuccess: OnSuccess, onError: OnError) {
        self.status = status
        ApiService.shared.updateJobWithId(String(id), params: ["status": status],
            onSuccess: { statusCode, mappingResult in
                JobService.shared.updateJob(self)
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    class Annotation: NSObject, MKAnnotation {
        private var job: Job!

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
