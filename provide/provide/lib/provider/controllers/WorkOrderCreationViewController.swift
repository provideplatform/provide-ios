//
//  WorkOrderCreationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 11/18/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit
import AVFoundation

protocol WorkOrderCreationViewControllerDelegate {
    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, numberOfSectionsInTableView tableView: UITableView) -> Int
    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, cellForTableView tableView: UITableView, atIndexPath indexPath: NSIndexPath) -> UITableViewCell!
    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didCreateWorkOrder workOrder: WorkOrder)
    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didCreateExpense expense: Expense)
    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, shouldBeDismissedWithWorkOrder workOrder: WorkOrder!)

}

class WorkOrderCreationViewController: WorkOrderDetailsViewController, ProviderPickerViewControllerDelegate, PDTSimpleCalendarViewDelegate, CameraViewControllerDelegate, ExpenseCaptureViewControllerDelegate {

    var delegate: WorkOrderCreationViewControllerDelegate!

    private var cancelItem: UIBarButtonItem! {
        let cancelItem = UIBarButtonItem(title: "CANCEL", style: .Plain, target: self, action: "cancel:")
        cancelItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return cancelItem
    }

    private var dismissItem: UIBarButtonItem! {
        let dismissItem = UIBarButtonItem(title: "DISMISS", style: .Plain, target: self, action: "dismiss:")
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return dismissItem
    }

    private var expenseItem: UIBarButtonItem! {
        let expenseItem = UIBarButtonItem(barButtonSystemItem: .Camera, target: self, action: "expense:")
        expenseItem.enabled = ["awaiting_schedule", "scheduled", "in_progress"].indexOfObject(workOrder.status) != nil
        return expenseItem
    }

    private var cameraItem: UIBarButtonItem! {
        let cameraItem = UIBarButtonItem(barButtonSystemItem: .Camera, target: self, action: "camera:")
        cameraItem.enabled = ["awaiting_schedule", "scheduled", "in_progress"].indexOfObject(workOrder.status) != nil
        return cameraItem
    }

    private var saveItem: UIBarButtonItem! {
        let saveItem = UIBarButtonItem(title: "SAVE", style: .Plain, target: self, action: "createWorkOrder:")
        saveItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return saveItem
    }

    private var disabledSaveItem: UIBarButtonItem! {
        let saveItem = UIBarButtonItem(title: "SAVE", style: .Plain, target: self, action: "createWorkOrder:")
        saveItem.setTitleTextAttributes(AppearenceProxy.barButtonItemDisabledTitleTextAttributes(), forState: .Normal)
        saveItem.enabled = false
        return saveItem
    }

    private var activityIndicatorView: UIActivityIndicatorView {
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .White)
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.startAnimating()
        return activityIndicatorView
    }

    private var isDirty = false

    private var reloadingJob = false

    private var isSaved: Bool {
        if let workOrder = workOrder {
            return workOrder.id > 0
        }
        return false
    }

    private var isValid: Bool {
        if let workOrder = workOrder {
            let validProviders = workOrder.providers.count > 0
            let validDate = workOrder.scheduledStartAt != nil
            return validProviders && validDate
        }
        return false
    }

    func cancel(sender: UIBarButtonItem!) {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .Alert : .ActionSheet
        let alertController = UIAlertController(title: "Are you sure you want to cancel and discard changes?", message: nil, preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Don't Cancel", style: .Default, handler: nil)
        alertController.addAction(cancelAction)

        let discardAction = UIAlertAction(title: "Discard", style: .Destructive) { action in
            self.delegate?.workOrderCreationViewController(self, shouldBeDismissedWithWorkOrder: nil)
        }

        alertController.addAction(cancelAction)
        alertController.addAction(discardAction)

        presentViewController(alertController, animated: true)
    }

    func dismiss(sender: UIBarButtonItem!) {
        delegate?.workOrderCreationViewController(self, shouldBeDismissedWithWorkOrder: workOrder)
    }

    func expense(sender: UIBarButtonItem!) {
        let expenseCaptureViewController = UIStoryboard("ExpenseCapture").instantiateInitialViewController() as! ExpenseCaptureViewController
        expenseCaptureViewController.modalPresentationStyle = .OverCurrentContext
        expenseCaptureViewController.expenseCaptureViewControllerDelegate = self

        presentViewController(expenseCaptureViewController, animated: true)
    }

    func camera(sender: UIBarButtonItem!) {
        let cameraViewController = UIStoryboard("Camera").instantiateInitialViewController() as! CameraViewController
        cameraViewController.delegate = self
        
        presentViewController(cameraViewController, animated: true)
    }

    func createWorkOrder(sender: UIBarButtonItem) {
        navigationItem.titleView = activityIndicatorView

        workOrder.save(
            onSuccess: { statusCode, mappingResult in
                self.isDirty = false
                if statusCode == 201 {
                    let wo = mappingResult.firstObject as! WorkOrder
                    self.workOrder.status = wo.status
                    self.delegate?.workOrderCreationViewController(self, didCreateWorkOrder: self.workOrder)
                }
                self.refreshUI()
            },
            onError: { error, statusCode, responseString in
                self.refreshUI()
            }
        )
    }

    private func refreshUI() {
        refreshTitle()
        refreshLeftBarButtonItems()
        refreshRightBarButtonItems()
    }

    private func refreshTitle() {
        navigationItem.title = workOrder.customer.contact.name
        navigationItem.titleView = nil
    }

    private func refreshLeftBarButtonItems() {
        if isSaved {
            navigationItem.leftBarButtonItems = [dismissItem]
        } else {
            navigationItem.leftBarButtonItems = [cancelItem]
        }
    }

    private func refreshRightBarButtonItems() {
        if isValid && isDirty {
            navigationItem.rightBarButtonItems = [saveItem]
        } else {
            navigationItem.rightBarButtonItems = [disabledSaveItem]
        }

        if isSaved {
            navigationItem.rightBarButtonItems!.append(cameraItem)
            navigationItem.rightBarButtonItems!.append(expenseItem)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "CREATE WORK ORDER"

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "WORK ORDER", style: .Plain, target: nil, action: nil)

        refreshUI()
    }

    // MARK: UITableViewDelegate

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let height = delegate?.workOrderCreationViewController(self, tableView: tableView, heightForRowAtIndexPath: indexPath) {
            return height
        }
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sectionCount = delegate?.workOrderCreationViewController(self, numberOfSectionsInTableView: tableView) {
            return sectionCount
        }
        return super.numberOfSectionsInTableView(tableView)
    }

    // MARK: UITableViewDataSource

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let rowCount = delegate?.workOrderCreationViewController(self, tableView: tableView, numberOfRowsInSection: section) {
            return rowCount
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell!

        if let c = delegate?.workOrderCreationViewController(self, cellForTableView: tableView, atIndexPath: indexPath) {
            cell = c
        } else {
            cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        }

        return cell
    }

    override func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return tableView.cellForRowAtIndexPath(indexPath)?.accessoryType == .DisclosureIndicator
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if tableView.cellForRowAtIndexPath(indexPath)?.accessoryType == .DisclosureIndicator {
            return indexPath
        }
        return nil
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let delegate = delegate {
            delegate.workOrderCreationViewController(self, tableView: tableView, didSelectRowAtIndexPath: indexPath)
        } else {
            super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        }
    }

    // MARK: ProviderPickerViewControllerDelegate

    func providerPickerViewController(viewController: ProviderPickerViewController, didSelectProvider provider: Provider) {
        if !workOrder.hasProvider(provider) {
            let workOrderProvider = WorkOrderProvider()
            workOrderProvider.provider = provider

            workOrder.workOrderProviders.append(workOrderProvider)
            isDirty = true
        }
        refreshRightBarButtonItems()
    }

    func providerPickerViewController(viewController: ProviderPickerViewController, didDeselectProvider provider: Provider) {
        workOrder.removeProvider(provider)
        isDirty = true
        refreshRightBarButtonItems()
    }

    func providerPickerViewControllerAllowsMultipleSelection(viewController: ProviderPickerViewController) -> Bool {
        return true
    }

    func providersForPickerViewController(viewController: ProviderPickerViewController) -> [Provider] {
        return workOrder.workOrderProviders.map({ $0.provider })
    }

    func selectedProvidersForPickerViewController(viewController: ProviderPickerViewController) -> [Provider] {
        return workOrder.workOrderProviders.map({ $0.provider })
    }

    // MARK: PDTSimpleCalendarViewControllerDelegate

    func simpleCalendarViewController(controller: PDTSimpleCalendarViewController!, didSelectDate date: NSDate!) {
        workOrder.scheduledStartAt = date.format("yyyy-MM-dd'T'HH:mm:ssZZ")
        isDirty = true
        refreshRightBarButtonItems()
    }

    func simpleCalendarViewController(controller: PDTSimpleCalendarViewController!, isEnabledDate date: NSDate!) -> Bool {
        if let scheduledStartAtDate = workOrder.scheduledStartAtDate {
            return scheduledStartAtDate.atMidnight != date.atMidnight
        }
        return true
    }

    // MARK: CameraViewControllerDelegate

    func outputModeForCameraViewController(viewController: CameraViewController) -> CameraOutputMode {
        return .Photo
    }

    func cameraViewControllerDidBeginAsyncStillImageCapture(viewController: CameraViewController) {
        cameraViewControllerCanceled(viewController)
    }

    func cameraViewController(viewController: CameraViewController, didCaptureStillImage image: UIImage) {
        navigationItem.titleView = activityIndicatorView

        var params: [String : AnyObject] = [
            "tags": ["photo"],
        ]

        if let location = LocationService.sharedService().currentLocation {
            params["latitude"] = location.coordinate.latitude
            params["longitude"] = location.coordinate.longitude
        }

        workOrder.attach(image, params: params,
            onSuccess: { (statusCode, mappingResult) -> () in
                self.refreshUI()
                self.reloadTableView()
            },
            onError: { (error, statusCode, responseString) -> () in
                self.refreshUI()
            }
        )
    }

    func cameraViewControllerCanceled(viewController: CameraViewController) {
        dismissViewController(animated: false)
    }

    func cameraViewController(viewController: CameraViewController, didSelectImageFromCameraRoll image: UIImage) {

    }

    func cameraViewControllerDidOutputFaceMetadata(viewController: CameraViewController, metadataFaceObject: AVMetadataFaceObject) {

    }

    func cameraViewControllerShouldOutputFaceMetadata(viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerShouldRenderFacialRecognition(viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerShouldOutputOCRMetadata(viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewController(cameraViewController: CameraViewController, didStartVideoCaptureAtURL fileURL: NSURL) {

    }
    
    func cameraViewController(cameraViewController: CameraViewController, didFinishVideoCaptureAtURL fileURL: NSURL) {
        
    }

    func cameraViewController(viewController: CameraViewController, didRecognizeText text: String!) {

    }

    // MARK: ManifestViewControllerDelegate

    override func workOrderForManifestViewController(viewController: UIViewController) -> WorkOrder! {
        return workOrder
    }

    func segmentsForManifestViewController(viewController: UIViewController) -> [String]! {
        return ["MATERIALS", "JOB MANIFEST"]
    }

    func itemsForManifestViewController(viewController: UIViewController, forSegmentIndex segmentIndex: Int) -> [Product]! {
        if segmentIndex == 0 {
            // work order manifest
            return workOrder.materials.map { $0.jobProduct.product }
        } else if segmentIndex == 1 {
            // job manifest
            if let job = workOrder.job {
                if let _ = job.materials {
                    return job.materials.map { $0.product }
                } else {
                    reloadWorkOrderJobForManifestViewController(viewController as! ManifestViewController)
                }
            } else {
                reloadWorkOrderJobForManifestViewController(viewController as! ManifestViewController)
            }
        }

        return [Product]()
    }

    private func reloadWorkOrderJobForManifestViewController(viewController: ManifestViewController) {
        if !reloadingJob {
            dispatch_async_main_queue {
                viewController.showActivityIndicator()
            }

            reloadingJob = true

            workOrder.reloadJob(
                { (statusCode, mappingResult) -> () in
                    self.refreshUI()
                    viewController.reloadTableView()
                    self.reloadingJob = false
                },
                onError: { (error, statusCode, responseString) -> () in
                    self.refreshUI()
                    viewController.reloadTableView()
                    self.reloadingJob = false
                }
            )
        }
    }

//    func itemsForManifestViewController(viewController: UIViewController) -> [Product]! {
//        return workOrder.materials.map { $0.jobProduct.product }
//    }

    override func navigationControllerBackItemTitleForManifestViewController(viewController: UIViewController) -> String! {
        return navigationItem.title
    }

    // MARK: ExpenseCaptureViewControllerDelegate
    
    func expensableForExpenseCaptureViewController(viewController: ExpenseCaptureViewController) -> Model {
        return workOrder
    }

    func expenseCaptureViewControllerBeganCreatingExpense(viewController: ExpenseCaptureViewController) {

    }

    func expenseCaptureViewController(viewController: ExpenseCaptureViewController, didCaptureReceipt receipt: UIImage, recognizedTexts texts: [String]!) {
        navigationItem.titleView = activityIndicatorView
    }

    func expenseCaptureViewController(viewController: ExpenseCaptureViewController, didCreateExpense expense: Expense) {
        refreshUI()
        delegate?.workOrderCreationViewController(self, didCreateExpense: expense)
    }

}
