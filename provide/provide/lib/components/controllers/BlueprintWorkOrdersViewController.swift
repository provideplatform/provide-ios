//
//  BlueprintWorkOrdersViewController.swift
//  provide
//
//  Created by Kyle Thomas on 4/11/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol BlueprintWorkOrdersViewControllerDelegate {
    func jobForBlueprintWorkOrdersViewController(viewController: BlueprintWorkOrdersViewController) -> Job!
    func blueprintWorkOrdersViewControllerDismissedPendingWorkOrder(viewController: BlueprintWorkOrdersViewController)
    func blueprintForBlueprintWorkOrdersViewController(viewController: BlueprintWorkOrdersViewController) -> Attachment!
    func blueprintViewControllerShouldRedrawAnnotationPinsForBlueprintWorkOrdersViewController(viewController: BlueprintWorkOrdersViewController)
    func blueprintViewControllerStartedReloadingAnnotationsForBlueprintWorkOrdersViewController(viewController: BlueprintWorkOrdersViewController)
    func blueprintViewControllerStoppedReloadingAnnotationsForBlueprintWorkOrdersViewController(viewController: BlueprintWorkOrdersViewController)
    func blueprintViewControllerShouldDeselectPinForBlueprintWorkOrdersViewController(viewController: BlueprintWorkOrdersViewController)
    func blueprintViewControllerShouldDeselectPolygonForBlueprintWorkOrdersViewController(viewController: BlueprintWorkOrdersViewController)
    func blueprintViewControllerShouldReloadToolbarForBlueprintWorkOrdersViewController(viewController: BlueprintWorkOrdersViewController)
    func blueprintViewControllerShouldRemovePinView(pinView: BlueprintPinView, forBlueprintWorkOrdersViewController viewController: BlueprintWorkOrdersViewController)
    func blueprintViewControllerShouldDismissWorkOrderCreationAnnotationViewsForBlueprintWorkOrdersViewController(viewController: BlueprintWorkOrdersViewController)
    func blueprintViewControllerShouldFocusOnWorkOrder(workOrder: WorkOrder, forBlueprintWorkOrdersViewController viewController: BlueprintWorkOrdersViewController)
    func selectedPinViewForBlueprintWorkOrdersViewController(viewController: BlueprintWorkOrdersViewController) -> BlueprintPinView!
    func selectedPolygonViewForBlueprintWorkOrdersViewController(viewController: BlueprintWorkOrdersViewController) -> BlueprintPolygonView!
    func pinViewForWorkOrder(workOrder: WorkOrder, forBlueprintWorkOrdersViewController viewController: BlueprintWorkOrdersViewController) -> BlueprintPinView!
    func polygonViewForWorkOrder(workOrder: WorkOrder, forBlueprintWorkOrdersViewController viewController: BlueprintWorkOrdersViewController) -> BlueprintPolygonView!
    func previewImageForWorkOrder(workOrder: WorkOrder, forBlueprintWorkOrdersViewController viewController: BlueprintWorkOrdersViewController) -> UIImage!
}

class BlueprintWorkOrdersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, WorkOrderCreationViewControllerDelegate {

    private let defaultWorkOrderFilteringStatuses = "abandoned,awaiting_schedule,scheduled,en_route,in_progress,rejected,paused,pending_approval,pending_final_approval"

    var delegate: BlueprintWorkOrdersViewControllerDelegate!

    private var annotations: [Annotation] {
        if let blueprint = blueprint {
            return blueprint.annotations
        }
        return [Annotation]()
    }

    private var blueprint: Attachment! {
        if let delegate = delegate {
            return  delegate.blueprintForBlueprintWorkOrdersViewController(self)
        }
        return nil
    }

    private var blueprintAnnotationsCount: Int {
        if let blueprint = blueprint {
            return blueprint.annotations.count
        }
        return 0
    }

    private var job: Job! {
        if let delegate = delegate {
            return delegate.jobForBlueprintWorkOrdersViewController(self)
        }
        return nil
    }

    private var newWorkOrderPending = false {
        didSet {
            if !newWorkOrderPending {
                delegate?.blueprintWorkOrdersViewControllerDismissedPendingWorkOrder(self)
            }
        }
    }

    private var workOrderStatuses: String!

    private var loadingAnnotations = false {
        didSet {
            if let delegate = delegate {
                if loadingAnnotations {
                    delegate.blueprintViewControllerStartedReloadingAnnotationsForBlueprintWorkOrdersViewController(self)
                } else {
                    delegate.blueprintViewControllerStoppedReloadingAnnotationsForBlueprintWorkOrdersViewController(self)
                }
            }
        }
    }

    @IBOutlet private weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if let navigationController = navigationController {
            if !navigationController.viewControllers.last!.isKindOfClass(WorkOrderCreationViewController) {
                navigationController.setNavigationBarHidden(true, animated: true)
            }
        }

        tableView?.reloadData()
    }

    func loadAnnotations() {
        if let blueprint = blueprint {
            if workOrderStatuses == nil {
                workOrderStatuses = defaultWorkOrderFilteringStatuses
            }

            loadingAnnotations = true
            blueprint.annotations = [Annotation]()
            let rpp = max(100, blueprintAnnotationsCount)
            let params = ["page": "1", "rpp": "\(rpp)", "work_order_status": workOrderStatuses]

            blueprint.fetchAnnotations(params,
                onSuccess: { statusCode, mappingResult in
                    self.loadingAnnotations = false

                    for annotation in mappingResult.array() as! [Annotation] {
                        if let workOrder = annotation.workOrder {
                            WorkOrderService.sharedService().updateWorkOrder(workOrder)
                        }
                    }

                    self.tableView?.reloadData()

                    if let delegate = self.delegate {
                        delegate.blueprintViewControllerShouldRedrawAnnotationPinsForBlueprintWorkOrdersViewController(self)
                    }
                },
                onError: { error, statusCode, responseString in
                    self.loadingAnnotations = false
                }
            )
        }
    }

    func cancelCreateWorkOrder(sender: UIBarButtonItem) {
        newWorkOrderPending = false
        delegate?.blueprintViewControllerShouldDismissWorkOrderCreationAnnotationViewsForBlueprintWorkOrdersViewController(self)
        delegate?.blueprintViewControllerShouldReloadToolbarForBlueprintWorkOrdersViewController(self)
    }

    func createWorkOrder(sender: AnyObject!) {
        let workOrder = WorkOrder()
        workOrder.company = job.company
        workOrder.companyId = job.companyId
        workOrder.customer = job.customer
        workOrder.customerId = job.customerId
        workOrder.job = job
        workOrder.jobId = job.id
        workOrder.status = "awaiting_schedule"
        workOrder.expenses = [Expense]()
        workOrder.itemsDelivered = [Product]()
        workOrder.itemsOrdered = [Product]()
        workOrder.itemsRejected = [Product]()
        workOrder.materials = [WorkOrderProduct]()

        openWorkOrder(workOrder)
    }

    func openWorkOrder(workOrder: WorkOrder) {
        var animated = true

        if let navigationController = navigationController {
            if navigationController.viewControllers.last!.isKindOfClass(WorkOrderCreationViewController) {
                animated = navigationController.view.superview!.frame.origin.x != navigationController.view.superview!.superview!.frame.width
                navigationController.popToRootViewControllerAnimated(animated)
            }
        }

        delegate?.previewImageForWorkOrder(workOrder, forBlueprintWorkOrdersViewController: self)

        let workOrderCreationViewController = UIStoryboard("WorkOrderCreation").instantiateInitialViewController() as! WorkOrderCreationViewController
        workOrderCreationViewController.workOrder = workOrder
        workOrderCreationViewController.delegate = self

        dispatch_after_delay(0.0) {
            self.navigationController?.setNavigationBarHidden(false, animated: animated && workOrder.id > 0)

            dispatch_after_delay(0.0) {
                self.navigationController?.pushViewController(workOrderCreationViewController, animated: animated && workOrder.id > 0)
            }
        }

        delegate?.blueprintViewControllerShouldFocusOnWorkOrder(workOrderCreationViewController.workOrder, forBlueprintWorkOrdersViewController: self)
    }

    private func setPreviewImageForWorkOrder(workOrder: WorkOrder) {

    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return annotations.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("blueprintWorkOrderTableViewCellReuseIdentifier") as! BlueprintWorkOrderTableViewCell
        cell.annotation = annotations[indexPath.row]
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let workOrder = (tableView.cellForRowAtIndexPath(indexPath) as! BlueprintWorkOrderTableViewCell).workOrder
        openWorkOrder(workOrder)

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    // MARK: WorkOrderCreationViewControllerDelegate

    func blueprintPinViewForWorkOrderCreationViewController(viewController: WorkOrderCreationViewController) -> BlueprintPinView! {
        if let workOrder = viewController.workOrder {
            if let delegate = delegate {
                return delegate.pinViewForWorkOrder(workOrder, forBlueprintWorkOrdersViewController: self)
            }
        }
        return nil
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, numberOfSectionsInTableView tableView: UITableView) -> Int {
        return 1
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return indexPath.section == 0 ? 75.0 : 44.0
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func workOrderCreationViewController(workOrderCreationViewController: WorkOrderCreationViewController, tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, cellForTableView tableView: UITableView, atIndexPath indexPath: NSIndexPath) -> UITableViewCell! {
        return nil
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didCreateWorkOrder workOrder: WorkOrder) {
        if let blueprint = blueprint {
            let annotation = Annotation()
            if let delegate = delegate {
                if let pinView = delegate.selectedPinViewForBlueprintWorkOrdersViewController(self) {
                    annotation.point = [pinView.point.x, pinView.point.y]
                } else if let polygonView = delegate.selectedPolygonViewForBlueprintWorkOrdersViewController(self) {
                    annotation.polygon = polygonView.polygon
                }
            }

            annotation.workOrderId = workOrder.id
            annotation.workOrder = workOrder
            annotation.save(blueprint,
                            onSuccess: { [weak self] statusCode, mappingResult in
                                self!.delegate?.blueprintViewControllerShouldRedrawAnnotationPinsForBlueprintWorkOrdersViewController(self!)
                                self!.delegate?.blueprintViewControllerShouldDismissWorkOrderCreationAnnotationViewsForBlueprintWorkOrdersViewController(self!)

                                self!.tableView.reloadData()

                                viewController.reloadTableView()
                },
                            onError: { error, statusCode, responseString in

                }
            )
        }
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didSubmitForApprovalWorkOrder workOrder: WorkOrder) {
        if let presentedViewController = presentedViewController {
            if presentedViewController is UINavigationController {
                let viewController = (presentedViewController as! UINavigationController).viewControllers.first!
                if viewController is WorkOrderCreationViewController {
                    presentedViewController.dismissViewController(animated: true) {
                        NSNotificationCenter.defaultCenter().postNotificationName("WorkOrderContextShouldRefresh")
                    }
                }
            }
        }
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didStartWorkOrder workOrder: WorkOrder) {
        viewController.reloadTableView()
        refreshPinViewForWorkOrder(workOrder)
        refreshPolygonViewForWorkOrder(workOrder)
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didCancelWorkOrder workOrder: WorkOrder) {
        viewController.reloadTableView()
        refreshPinViewForWorkOrder(workOrder)
        refreshPolygonViewForWorkOrder(workOrder)
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didCompleteWorkOrder workOrder: WorkOrder) {
        viewController.reloadTableView()
        refreshPinViewForWorkOrder(workOrder)
        refreshPolygonViewForWorkOrder(workOrder)
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didApproveWorkOrder workOrder: WorkOrder) {
        viewController.reloadTableView()
        refreshPinViewForWorkOrder(workOrder)
        refreshPolygonViewForWorkOrder(workOrder)
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didRejectWorkOrder workOrder: WorkOrder) {
        viewController.reloadTableView()
        refreshPinViewForWorkOrder(workOrder)
        refreshPolygonViewForWorkOrder(workOrder)
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didRestartWorkOrder workOrder: WorkOrder) {
        viewController.reloadTableView()
        refreshPinViewForWorkOrder(workOrder)
        refreshPolygonViewForWorkOrder(workOrder)
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didCreateExpense expense: Expense) {
        if let presentedViewController = presentedViewController {
            if presentedViewController is UINavigationController {
                let viewController = (presentedViewController as! UINavigationController).viewControllers.first!
                if viewController is WorkOrderCreationViewController {
                    (viewController as! WorkOrderCreationViewController).workOrder.prependExpense(expense)
                    (viewController as! WorkOrderCreationViewController).reloadTableView()
                }
            }
        }

        refreshWorkOrderCreationView()
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, shouldBeDismissedWithWorkOrder workOrder: WorkOrder!) {
        newWorkOrderPending = false
        navigationController?.popViewControllerAnimated(true)
        delegate?.blueprintViewControllerShouldReloadToolbarForBlueprintWorkOrdersViewController(self)
        if workOrder == nil {
            if let selectedPinView = delegate?.selectedPinViewForBlueprintWorkOrdersViewController(self) {
                delegate?.blueprintViewControllerShouldRemovePinView(selectedPinView, forBlueprintWorkOrdersViewController: self)
            }
        }

        delegate?.blueprintViewControllerShouldDeselectPinForBlueprintWorkOrdersViewController(self)
        delegate?.blueprintViewControllerShouldDeselectPolygonForBlueprintWorkOrdersViewController(self)
    }

    func flatFeeForNewProvider(provider: Provider, forWorkOrderCreationViewController viewController: WorkOrderCreationViewController) -> Double! {
        return nil
    }

    private func refreshWorkOrderCreationView() {
        if let presentedViewController = presentedViewController {
            if presentedViewController is UINavigationController {
                let viewController = (presentedViewController as! UINavigationController).viewControllers.first!
                if viewController is WorkOrderCreationViewController {
                    (viewController as! WorkOrderCreationViewController).reloadTableView()
                }
            }
        }
    }

    private func refreshPinViewForWorkOrder(workOrder: WorkOrder) {
        if let pinView = delegate?.pinViewForWorkOrder(workOrder, forBlueprintWorkOrdersViewController: self) {
            pinView.redraw()
        }
    }

    private func refreshPolygonViewForWorkOrder(workOrder: WorkOrder) {
        if let polygonView = delegate?.polygonViewForWorkOrder(workOrder, forBlueprintWorkOrdersViewController: self) {
            polygonView.redraw()
        }
    }
}
