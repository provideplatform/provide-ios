//
//  FloorplanWorkOrdersViewController.swift
//  provide
//
//  Created by Kyle Thomas on 4/11/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

protocol FloorplanWorkOrdersViewControllerDelegate {
    func jobForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController) -> Job!
    func floorplanWorkOrdersViewControllerDismissedPendingWorkOrder(_ viewController: FloorplanWorkOrdersViewController)
    func floorplanForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController) -> Floorplan!
    func floorplanViewControllerShouldRedrawAnnotationPinsForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController)
    func floorplanViewControllerStartedReloadingAnnotationsForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController)
    func floorplanViewControllerStoppedReloadingAnnotationsForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController)
    func floorplanViewControllerShouldDeselectPinForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController)
    func floorplanViewControllerShouldDeselectPolygonForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController)
    func floorplanViewControllerShouldReloadToolbarForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController)
    func floorplanViewControllerShouldRemovePinView(_ pinView: FloorplanPinView, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController)
    func floorplanViewControllerShouldDismissWorkOrderCreationAnnotationViewsForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController)
    func floorplanViewControllerShouldFocusOnWorkOrder(_ workOrder: WorkOrder, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController)
    func selectedPinViewForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController) -> FloorplanPinView!
    func selectedPolygonViewForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController) -> FloorplanPolygonView!
    func sizeForFloorplanWorkOrdersViewController(_ viewController: FloorplanWorkOrdersViewController) -> CGSize!
    func pinViewForWorkOrder(_ workOrder: WorkOrder, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController) -> FloorplanPinView!
    func polygonViewForWorkOrder(_ workOrder: WorkOrder, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController) -> FloorplanPolygonView!
    func previewImageForWorkOrder(_ workOrder: WorkOrder, forFloorplanWorkOrdersViewController viewController: FloorplanWorkOrdersViewController) -> UIImage!
}

class FloorplanWorkOrdersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, WorkOrderCreationViewControllerDelegate {

    fileprivate let defaultWorkOrderFilteringStatuses = "abandoned,awaiting_schedule,scheduled,delayed,en_route,in_progress,rejected,paused,pending_approval,pending_final_approval"

    var delegate: FloorplanWorkOrdersViewControllerDelegate!

    fileprivate var annotations: [Annotation] {
        if let floorplan = floorplan {
            if let annotations = floorplan.annotations {
                return annotations
            }
        }
        return [Annotation]()
    }

    fileprivate var floorplan: Floorplan! {
        if let delegate = delegate {
            return  delegate.floorplanForFloorplanWorkOrdersViewController(self)
        }
        return nil
    }

    fileprivate var floorplanAnnotationsCount: Int {
        return annotations.count
    }

    fileprivate var job: Job! {
        if let delegate = delegate {
            return delegate.jobForFloorplanWorkOrdersViewController(self)
        }
        return nil
    }

    fileprivate var newWorkOrderPending = false {
        didSet {
            if !newWorkOrderPending {
                delegate?.floorplanWorkOrdersViewControllerDismissedPendingWorkOrder(self)
            }
        }
    }

    fileprivate var workOrderStatuses: String!

    fileprivate var loadingAnnotations = false {
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

    @IBOutlet fileprivate weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let navigationController = navigationController {
            if !navigationController.viewControllers.last!.isKind(of: WorkOrderCreationViewController.self) {
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

            floorplan.fetchAnnotations(params as [String : AnyObject],
                onSuccess: { statusCode, mappingResult in
                    self.loadingAnnotations = false

                    for annotation in mappingResult?.array() as! [Annotation] {
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

    func cancelCreateWorkOrder(_ sender: UIBarButtonItem) {
        newWorkOrderPending = false
        delegate?.floorplanViewControllerShouldDismissWorkOrderCreationAnnotationViewsForFloorplanWorkOrdersViewController(self)
        delegate?.floorplanViewControllerShouldReloadToolbarForFloorplanWorkOrdersViewController(self)
    }

    func createWorkOrder(_ sender: AnyObject!) {
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

    func openWorkOrder(_ workOrder: WorkOrder) {
        var animated = true

        if let navigationController = navigationController {
            if navigationController.viewControllers.last!.isKind(of: WorkOrderCreationViewController.self) {
                animated = navigationController.view.superview!.frame.origin.x != navigationController.view.superview!.superview!.frame.width
                navigationController.popToRootViewController(animated: animated)
            }
        }

        let _ = delegate?.previewImageForWorkOrder(workOrder, forFloorplanWorkOrdersViewController: self)

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

    fileprivate func setPreviewImageForWorkOrder(_ workOrder: WorkOrder) {

    }

    // MARK: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return annotations.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "floorplanWorkOrderTableViewCellReuseIdentifier") as! FloorplanWorkOrderTableViewCell
        cell.annotation = annotations[(indexPath as NSIndexPath).section]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let workOrder = (tableView.cellForRow(at: indexPath) as! FloorplanWorkOrderTableViewCell).workOrder
        openWorkOrder(workOrder!)

        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: WorkOrderCreationViewControllerDelegate

    func floorplanPinViewForWorkOrderCreationViewController(_ viewController: WorkOrderCreationViewController) -> FloorplanPinView! {
        if let workOrder = viewController.workOrder {
            if let delegate = delegate {
                return delegate.pinViewForWorkOrder(workOrder, forFloorplanWorkOrdersViewController: self)
            }
        }
        return nil
    }

    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, numberOfSectionsInTableView tableView: UITableView) -> Int {
        return 1
    }

    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat {
        return (indexPath as NSIndexPath).section >= 0 ? 75.0 : 44.0
    }

    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func workOrderCreationViewController(_ workOrderCreationViewController: WorkOrderCreationViewController, tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {

    }

    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, cellForTableView tableView: UITableView, atIndexPath indexPath: IndexPath) -> UITableViewCell! {
        return nil
    }

    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, didCreateWorkOrder workOrder: WorkOrder) {
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

    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, didSubmitForApprovalWorkOrder workOrder: WorkOrder) {
        if let presentedViewController = presentedViewController {
            if presentedViewController is UINavigationController {
                let viewController = (presentedViewController as! UINavigationController).viewControllers.first!
                if viewController is WorkOrderCreationViewController {
                    presentedViewController.dismissViewController(true) {
                        NotificationCenter.default.postNotificationName("WorkOrderContextShouldRefresh")
                    }
                }
            }
        }
    }

    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, didStartWorkOrder workOrder: WorkOrder) {
        viewController.reloadTableView()
        refreshPinViewForWorkOrder(workOrder)
        refreshPolygonViewForWorkOrder(workOrder)
    }

    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, didCancelWorkOrder workOrder: WorkOrder) {
        viewController.reloadTableView()
        refreshPinViewForWorkOrder(workOrder)
        refreshPolygonViewForWorkOrder(workOrder)
    }

    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, didCompleteWorkOrder workOrder: WorkOrder) {
        viewController.reloadTableView()
        refreshPinViewForWorkOrder(workOrder)
        refreshPolygonViewForWorkOrder(workOrder)
    }

    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, didApproveWorkOrder workOrder: WorkOrder) {
        viewController.reloadTableView()
        refreshPinViewForWorkOrder(workOrder)
        refreshPolygonViewForWorkOrder(workOrder)
    }

    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, didRejectWorkOrder workOrder: WorkOrder) {
        viewController.reloadTableView()
        refreshPinViewForWorkOrder(workOrder)
        refreshPolygonViewForWorkOrder(workOrder)
    }

    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, didRestartWorkOrder workOrder: WorkOrder) {
        viewController.reloadTableView()
        refreshPinViewForWorkOrder(workOrder)
        refreshPolygonViewForWorkOrder(workOrder)
    }

    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, didCreateExpense expense: Expense) {
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

    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, shouldBeDismissedWithWorkOrder workOrder: WorkOrder!) {
        newWorkOrderPending = false
        let _ = navigationController?.popViewController(animated: true)
        delegate?.floorplanViewControllerShouldReloadToolbarForFloorplanWorkOrdersViewController(self)
        if workOrder == nil {
            if let selectedPinView = delegate?.selectedPinViewForFloorplanWorkOrdersViewController(self) {
                delegate?.floorplanViewControllerShouldRemovePinView(selectedPinView, forFloorplanWorkOrdersViewController: self)
            }
        }

        delegate?.floorplanViewControllerShouldDeselectPinForFloorplanWorkOrdersViewController(self)
        delegate?.floorplanViewControllerShouldDeselectPolygonForFloorplanWorkOrdersViewController(self)
    }

    func flatFeeForNewProvider(_ provider: Provider, forWorkOrderCreationViewController viewController: WorkOrderCreationViewController) -> Double! {
        return nil
    }

    fileprivate func refreshWorkOrderCreationView() {
        if let presentedViewController = presentedViewController {
            if presentedViewController is UINavigationController {
                let viewController = (presentedViewController as! UINavigationController).viewControllers.first!
                if viewController is WorkOrderCreationViewController {
                    (viewController as! WorkOrderCreationViewController).reloadTableView()
                }
            }
        }
    }

    fileprivate func refreshPinViewForWorkOrder(_ workOrder: WorkOrder) {
        if let pinView = delegate?.pinViewForWorkOrder(workOrder, forFloorplanWorkOrdersViewController: self) {
            pinView.redraw()
        }
    }

    fileprivate func refreshPolygonViewForWorkOrder(_ workOrder: WorkOrder) {
        if let polygonView = delegate?.polygonViewForWorkOrder(workOrder, forFloorplanWorkOrdersViewController: self) {
            polygonView.redraw()
        }
    }
}
