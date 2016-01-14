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
    var contractRevenue = -1.0
    var cost = -1.0
    var attachments: [Attachment]!
    var blueprints: [Attachment]!
    var blueprintImageUrlString: String!
    var blueprintScale = 0.0
    var blueprintAnnotationsCount = 0
    var status: String!
    var expenses: [Expense]!
    var expensesCount = 0
    var expensedAmount = -1.0
    var laborCost = -1.0
    var laborCostPerSqFt = -1.0
    var laborCostPercentageOfRevenue = -1.0
    var materialsCost = -1.0
    var materialsCostPerSqFt = -1.0
    var materialsCostPercentageOfRevenue = -1.0
    var materials: [JobProduct]!
    var profit: NSNumber!
    var profitMargin: NSNumber!
    var profitPerSqFt: NSNumber!
    var quotedPricePerSqFt = -1.0
    var supervisors: [Provider]!
    var totalSqFt = -1.0
    var workOrdersCount = 0
    var wizardMode: NSNumber!

    var isWizardMode: Bool {
        if let wizardMode = wizardMode {
            return wizardMode.boolValue
        }
        return false
    }

    override class func mapping() -> RKObjectMapping {
        let mapping = RKObjectMapping(forClass: self)
        mapping.addAttributeMappingsFromDictionary([
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
            ])
        mapping.addRelationshipMappingWithSourceKeyPath("company", mapping: Company.mapping())
        mapping.addRelationshipMappingWithSourceKeyPath("customer", mapping: Customer.mapping())
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "attachments", toKeyPath: "attachments", withMapping: Attachment.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "blueprints", toKeyPath: "blueprints", withMapping: Attachment.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "comments", toKeyPath: "comments", withMapping: Comment.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "expenses", toKeyPath: "expenses", withMapping: Expense.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "materials", toKeyPath: "materials", withMapping: JobProduct.mapping()))
        mapping.addPropertyMapping(RKRelationshipMapping(fromKeyPath: "supervisors", toKeyPath: "supervisors", withMapping: Provider.mapping()))
        return mapping
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

        return UIColor.clearColor()
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

    func prependExpense(expense: Expense) {
        if expenses == nil {
            expenses = [Expense]()

            if expensedAmount == -1.0 {
                expensedAmount = 0.0
            }
        }

        expenses.insert(expense, atIndex: 0)

        expensesCount += 1
        expensedAmount += expense.amount
    }

    func addComment(comment: String, onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().addComment(comment, toJobWithId: String(id),
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
            ApiService.sharedService().fetchComments(forJobWithId: String(id),
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
                "include_expenses": "true",
                "include_products": "true",
                "include_supervisors": "true",
            ]

            reload(params,
                onSuccess: { statusCode, mappingResult in
                    let job = mappingResult.firstObject as! Job

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
            ApiService.sharedService().fetchExpenses(forJobWithId: String(id),
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

    func addExpense(params: [String: AnyObject], receipt: UIImage!, onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().createExpense(params, forExpensableType: "job",
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
        if !hasSupervisor(supervisor) {
            supervisors.append(supervisor)
            save(onSuccess: onSuccess, onError: onError)
        }
    }
    
    func removeSupervisor(supervisor: Provider, onSuccess: OnSuccess, onError: OnError) {
        if hasSupervisor(supervisor) {
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
            let params: [String : AnyObject] = ["include_products": "true"]
            ApiService.sharedService().fetchJobWithId(String(id), params: params,
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

    func addJobProductForProduct(product: Product, params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) {
        if jobProductForProduct(product) == nil && materials != nil {
            let jobProduct = JobProduct()
            jobProduct.jobId = id
            jobProduct.productId = product.id

            if let initialQuantity = params["initialQuantity"] as? Double {
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
                        { statusCode, mappingResult in
                            onSuccess(statusCode: statusCode, mappingResult: saveMappingResult)
                        },
                        onError: { error, statusCode, responseString in
                            onError(error: error, statusCode: statusCode, responseString: responseString)
                        }
                    )
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        }
    }

    func removeJobProductForProduct(product: Product, onSuccess: OnSuccess, onError: OnError) {
        if let jobProduct = jobProductForProduct(product) {
            removeJobProduct(jobProduct, onSuccess: onSuccess, onError: onError)
        }
    }

    func removeJobProduct(jobProduct: JobProduct, onSuccess: OnSuccess, onError: OnError) {
        materials.removeObject(jobProduct)
        save(onSuccess: onSuccess, onError: onError)
    }

    func reloadSupervisors(onSuccess: OnSuccess, onError: OnError) {
        if id > 0 {
            let params: [String : AnyObject] = ["include_supervisors": "true"]
            ApiService.sharedService().fetchJobWithId(String(id), params: params,
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

    func reload(onSuccess onSuccess: OnSuccess, onError: OnError) {
        reload([String : AnyObject](), onSuccess: onSuccess, onError: onError)
    }

    func reload(params: [String : AnyObject], onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().fetchJobWithId(String(id), params: params,
            onSuccess: { statusCode, mappingResult in
                let job = mappingResult.firstObject as! Job
                self.blueprints = job.blueprints
                self.blueprintImageUrlString = job.blueprintImageUrlString

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

    func cancel(onSuccess onSuccess: OnSuccess, onError: OnError) {
        ApiService.sharedService().updateJobWithId(String(id), params: ["status": "canceled"],
            onSuccess: { statusCode, mappingResult in
                self.status = "canceled"
                onSuccess(statusCode: statusCode, mappingResult: mappingResult)
            },
            onError: { error, statusCode, responseString in
                onError(error: error, statusCode: statusCode, responseString: responseString)
            }
        )
    }

    func save(onSuccess onSuccess: OnSuccess, onError: OnError) {
        var params = toDictionary()
        params.removeValueForKey("id")

        if id > 0 {
            if let materials = materials {
                var jobProducts = [[String : AnyObject]]()
                for jobProduct in materials {
                    var jp: [String : AnyObject] = ["job_id": id, "product_id": jobProduct.productId, "initial_quantity": jobProduct.initialQuantity]
                    if jobProduct.price > -1.0 {
                        jp.updateValue(jobProduct.price, forKey: "price")
                    }
                    if jobProduct.id > 0 {
                        jp.updateValue(jobProduct.id, forKey: "id")
                    }
                    jobProducts.append(jp)
                }
                params.updateValue(jobProducts, forKey: "materials")
            }

            ApiService.sharedService().updateJobWithId(String(id), params: params,
                onSuccess: { statusCode, mappingResult in
                    onSuccess(statusCode: statusCode, mappingResult: mappingResult)
                },
                onError: { error, statusCode, responseString in
                    onError(error: error, statusCode: statusCode, responseString: responseString)
                }
            )
        } else {
            ApiService.sharedService().createJob(params,
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
