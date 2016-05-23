//
//  FloorplanWorkOrdersViewController.swift
//  provide
//
//  Created by Kyle Thomas on 4/11/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol BlueprintWorkOrdersViewControllerDelegate {
    func jobForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController) -> Job!
    func floorplanWorkOrdersViewControllerDismissedPendingWorkOrder(viewController: FloorplanWorkOrdersViewController)
    func floorplanForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController) -> Floorplan!
    func floorplanViewControllerShouldRedrawAnnotationPinsForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController)
    func floorplanViewControllerStartedReloadingAnnotationsForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController)
    func floorplanViewControllerStoppedReloadingAnnotationsForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController)
    func floorplanViewControllerShouldDeselectPinForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController)
    func floorplanViewControllerShouldDeselectPolygonForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController)
    func floorplanViewControllerShouldReloadToolbarForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController)
    func floorplanViewControllerShouldRemovePinView(pinView: BlueprintPinView, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController)
    func floorplanViewControllerShouldDismissWorkOrderCreationAnnotationViewsForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController)
    func floorplanViewControllerShouldFocusOnWorkOrder(workOrder: WorkOrder, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController)
    func selectedPinViewForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController) -> BlueprintPinView!
    func selectedPolygonViewForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController) -> BlueprintPolygonView!
    func sizeForFloorplanWorkOrdersViewController(viewController: FloorplanWorkOrdersViewController) -> CGSize!
    func pinViewForWorkOrder(workOrder: WorkOrder, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController) -> BlueprintPinView!
    func polygonViewForWorkOrder(workOrder: WorkOrder, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController) -> BlueprintPolygonView!
    func previewImageForWorkOrder(workOrder: WorkOrder, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController) -> UIImage!
}

class FloorplanWorkOrdersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, WorkOrderCreationViewControllerDelegate {

    private let defaultWorkOrderFilteringStatuses = "abandoned,awaiting_schedule,scheduled,delayed,en_route,in_progress,rejected,paused,pending_approval,pending_final_approval"

    var delegate: BlueprintWorkOrdersViewControllerDelegate!

    private var annotations: [Annotation] {
        if let floorplan = floorplan {
            if let annotations = floorplan.annotations {
                return annotations
            }
        }
        return [Annotation]()
    }

    private var floorplan: Floorplan! {
        if let delegate = delegate {
            return  delegate.floorplanForFloorplanWorkOrdersViewController(self)
        }
        return nil
    }

    private var floorplanAnnotationsCount: Int {
        return annotations.count
    }

    private var job: Job! {
        if let delegate = delegate {
            return delegate.jobForFloorplanWorkOrdersViewController(self)
        }
        return nil
    }

    private var newWorkOrderPending = false {
        didSet {
            if !newWorkOrderPending {
                delegate?.floorplanWorkOrdersViewControllerDismissedPendingWorkOrder(self)
            }
        }
    }

    private var workOrderStatuses: String!

    private var loadingAnnotations = false {
        didSet {
            if let delegate = delegate {
                if loadingAnnotations {
                    delegate.floorplanViewControllerStartedReloadingAnnotationsForFloorplanWorkOrdersViewController(self)
                } else {
                    delegate.floorplanViewControllerStoppedReloadingAnnotationsForFloorplanWorkOrdersViewController(self)
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
        if let floorplan = floorplan {
            if workOrderStatuses == nil {
                workOrderStatuses = defaultWorkOrderFilteringStatuses
            }

            loadingAnnotations = true
            floorplan.workOrders = [WorkOrder]()
            let rpp = max(100, floorplanAnnotationsCount)
            let params = ["page": "1", "rpp": "\(rpp)", "work_order_status": workOrderStatuses]

            floorplan.fetchAnnotations(params,
                onSuccess: { statusCode, mappingResult in
                    self.loadingAnnotations = false

                    for annotation in mappingResult.array() as! [Annotation] {
                        if let workOrder = annotation.workOrder {
                            WorkOrderService.sharedService().updateWorkOrder(workOrder)
                        }
                    }

                    self.tableView?.reloadData()

                    if let delegate = self.delegate {
                        delegate.floorplanViewControllerShouldRedrawAnnotationPinsForFloorplanWorkOrdersViewController(self)
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
        delegate?.floorplanViewControllerShouldDismissWorkOrderCreationAnnotationViewsForFloorplanWorkOrdersViewController(self)
        delegate?.floorplanViewControllerShouldReloadToolbarForFloorplanWorkOrdersViewController(self)
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

        delegate?.previewImageForWorkOrder(workOrder, forFloorplanWorkOrdersViewController: self)

        let workOrderCreationViewController = UIStoryboard("WorkOrderCreation").instantiateInitialViewController() as! WorkOrderCreationViewController
        workOrderCreationViewController.workOrder = workOrder
        workOrderCreationViewController.delegate = self

        dispatch_after_delay(0.0) {
            self.navigationController?.setNavigationBarHidden(false, animated: animated && workOrder.id > 0)

            dispatch_after_delay(0.0) {
                self.navigationController?.pushViewController(workOrderCreationViewController, animated: animated && workOrder.id > 0)
            }
        }

        delegate?.floorplanViewControllerShouldFocusOnWorkOrder(workOrderCreationViewController.workOrder, forFloorplanWorkOrdersViewController: self)
    }

    private func setPreviewImageForWorkOrder(workOrder: WorkOrder) {

    }

    // MARK: UITableViewDataSource

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return annotations.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("blueprintWorkOrderTableViewCellReuseIdentifier") as! BlueprintWorkOrderTableViewCell
        cell.annotation = annotations[indexPath.section]
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
                return delegate.pinViewForWorkOrder(workOrder, forFloorplanWorkOrdersViewController: self)
            }
        }
        return nil
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, numberOfSectionsInTableView tableView: UITableView) -> Int {
        return 1
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return indexPath.section >= 0 ? 75.0 : 44.0
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
        if let floorplan = floorplan {
            let annotation = Annotation()
            if let delegate = delegate {
                if let pinView = delegate.selectedPinViewForFloorplanWorkOrdersViewController(self) {
                    if let size = delegate.sizeForFloorplanWorkOrdersViewController(self) {
                        annotation.point = [pinView.point.x / size.width, pinView.point.y / size.height]
                    }
                }
            }

            annotation.workOrderId = workOrder.id
            annotation.workOrder = workOrder
            annotation.save(floorplan,
                onSuccess: { [weak self] statusCode, mappingResult in
                    self!.delegate?.floorplanViewControllerShouldRedrawAnnotationPinsForFloorplanWorkOrdersViewController(self!)
                    self!.delegate?.floorplanViewControllerShouldDismissWorkOrderCreationAnnotationViewsForFloorplanWorkOrdersViewController(self!)

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
        delegate?.floorplanViewControllerShouldReloadToolbarForFloorplanWorkOrdersViewController(self)
        if workOrder == nil {
            if let selectedPinView = delegate?.selectedPinViewForFloorplanWorkOrdersViewController(self) {
                delegate?.floorplanViewControllerShouldRemovePinView(selectedPinView, forFloorplanWorkOrdersViewController: self)
            }
        }

        delegate?.floorplanViewControllerShouldDeselectPinForFloorplanWorkOrdersViewController(self)
        delegate?.floorplanViewControllerShouldDeselectPolygonForFloorplanWorkOrdersViewController(self)
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
        if let pinView = delegate?.pinViewForWorkOrder(workOrder, forFloorplanWorkOrdersViewController: self) {
            pinView.redraw()
        }
    }

    private func refreshPolygonViewForWorkOrder(workOrder: WorkOrder) {
        if let polygonView = delegate?.polygonViewForWorkOrder(workOrder, forFloorplanWorkOrdersViewController: self) {
            polygonView.redraw()
        }
    }
}
