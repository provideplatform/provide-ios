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
    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didStartWorkOrder workOrder: WorkOrder)
    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didCancelWorkOrder workOrder: WorkOrder)
    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didCompleteWorkOrder workOrder: WorkOrder)
    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, didCreateExpense expense: Expense)
    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, shouldBeDismissedWithWorkOrder workOrder: WorkOrder!)
    func flatFeeForNewProvider(provider: Provider, forWorkOrderCreationViewController viewController: WorkOrderCreationViewController) -> Double!
}

class WorkOrderCreationViewController: WorkOrderDetailsViewController,
                                       PDTSimpleCalendarViewDelegate,
                                       DurationPickerViewDelegate,
                                       CameraViewControllerDelegate,
                                       ExpenseCaptureViewControllerDelegate,
                                       TaskListViewControllerDelegate,
                                       WorkOrderTeamViewControllerDelegate,
                                       WorkOrderInventoryViewControllerDelegate,
                                       UIPopoverPresentationControllerDelegate {

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
        let expenseItemImage = FAKFontAwesome.dollarIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0))
        let expenseBarButtonItem = NavigationBarButton.barButtonItemWithImage(expenseItemImage, target: self, action: "expense:")
        expenseBarButtonItem.enabled = ["awaiting_schedule", "scheduled", "in_progress"].indexOfObject(workOrder.status) != nil
        return expenseBarButtonItem
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

    private var taskListItem: UIBarButtonItem! {
        let taskListIconImage = FAKFontAwesome.tasksIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0)).imageWithRenderingMode(.AlwaysTemplate)
        let taskListItem = UIBarButtonItem(image: taskListIconImage, style: .Plain, target: self, action: "showTaskList:")
        taskListItem.tintColor = Color.applicationDefaultBarButtonItemTintColor()
        return taskListItem
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
            let validDate = workOrder.scheduledStartAt != nil
            return validDate
        }
        return false
    }

    func cancel(sender: UIBarButtonItem!) {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .Alert : .ActionSheet
        let alertController = UIAlertController(title: "Are you sure you want to cancel and discard changes?", message: nil, preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Don't Cancel", style: .Default, handler: nil)
        alertController.addAction(cancelAction)

        let discardAction = UIAlertAction(title: "Discard", style: .Destructive) { [weak self] action in
            self!.delegate?.workOrderCreationViewController(self!, shouldBeDismissedWithWorkOrder: nil)
        }

        alertController.addAction(cancelAction)
        alertController.addAction(discardAction)

        presentViewController(alertController, animated: true)
    }

    func dismiss(sender: UIBarButtonItem!) {
        if isDirty {
            let preferredStyle: UIAlertControllerStyle = isIPad() ? .Alert : .ActionSheet
            let alertController = UIAlertController(title: "Are you sure you want to cancel and discard changes?", message: nil, preferredStyle: preferredStyle)

            let cancelAction = UIAlertAction(title: "Don't Dismiss", style: .Default, handler: nil)
            alertController.addAction(cancelAction)

            let discardAction = UIAlertAction(title: "Yes, Discard Pending Changes", style: .Destructive) { [weak self] action in
                self!.forceDismiss()
            }

            alertController.addAction(cancelAction)
            alertController.addAction(discardAction)
            
            presentViewController(alertController, animated: true)
        } else {
            forceDismiss()
        }
    }

    private func forceDismiss() {
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
        createWorkOrder()
    }

    func createWorkOrder() {
        navigationItem.titleView = activityIndicatorView

        workOrder.save(
            onSuccess: { statusCode, mappingResult in
                self.isDirty = false
                if statusCode == 201 {
                    let wo = mappingResult.firstObject as! WorkOrder
                    self.workOrder.status = wo.status
                    self.reloadTableView()
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
            navigationItem.rightBarButtonItems!.append(taskListItem)
        }
    }

    func showTaskList(sender: UIBarButtonItem) {
        let taskListNavigationController = UIStoryboard("TaskList").instantiateInitialViewController() as! UINavigationController
        (taskListNavigationController.viewControllers.first! as! TaskListViewController).taskListViewControllerDelegate = self
        taskListNavigationController.modalPresentationStyle = .Popover
        taskListNavigationController.preferredContentSize = CGSizeMake(300, 250)
        taskListNavigationController.popoverPresentationController!.barButtonItem = sender
        taskListNavigationController.popoverPresentationController!.permittedArrowDirections = [.Right]
        taskListNavigationController.popoverPresentationController!.canOverlapSourceViewRect = false
        presentViewController(taskListNavigationController, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "CREATE WORK ORDER"

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "WORK ORDER", style: .Plain, target: nil, action: nil)

        refreshUI()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        refreshUI()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier! == "WorkOrderTeamViewControllerEmbedSegue" {
            (segue.destinationViewController as! WorkOrderTeamViewController).delegate = self
        }
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

    // MARK: WorkOrderDetailsHeaderTableViewControllerDelegate

    override func workOrderDetailsHeaderTableViewController(viewController: WorkOrderDetailsHeaderTableViewController, shouldStartWorkOrder workOrder: WorkOrder) {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .Alert : .ActionSheet
        let alertController = UIAlertController(title: "Are you sure you want to start this work order?", message: "This cannot be undone.", preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Don't Start", style: .Default, handler: nil)
        alertController.addAction(cancelAction)

        let startAction = UIAlertAction(title: "Yes, Manually Start Work Order", style: .Destructive) { action in
            self.workOrder.arrive(
                onSuccess: { statusCode, mappingResult in
                    viewController.tableView.reloadData()
                    self.delegate?.workOrderCreationViewController(self, didStartWorkOrder: workOrder)
                },
                onError: { error, statusCode, responseString in
                    viewController.tableView.reloadData()
                }
            )
        }

        alertController.addAction(cancelAction)
        alertController.addAction(startAction)

        presentViewController(alertController, animated: true)
    }

    override func workOrderDetailsHeaderTableViewController(viewController: WorkOrderDetailsHeaderTableViewController, shouldCancelWorkOrder workOrder: WorkOrder) {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .Alert : .ActionSheet
        let alertController = UIAlertController(title: "Are you sure you want to cancel this work order?", message: "This cannot be undone.", preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Don't Cancel", style: .Default, handler: nil)
        alertController.addAction(cancelAction)

        let cancelWorkOrderAction = UIAlertAction(title: "Yes, Cancel Work Order", style: .Destructive) { action in
            self.workOrder.cancel(
                onSuccess: { statusCode, mappingResult in
                    viewController.tableView.reloadData()
                    self.delegate?.workOrderCreationViewController(self, didCancelWorkOrder: workOrder)
                },
                onError: { error, statusCode, responseString in
                    viewController.tableView.reloadData()
                }
            )
        }

        alertController.addAction(cancelAction)
        alertController.addAction(cancelWorkOrderAction)

        presentViewController(alertController, animated: true)
    }

    override func workOrderDetailsHeaderTableViewController(viewController: WorkOrderDetailsHeaderTableViewController, shouldCompleteWorkOrder workOrder: WorkOrder) {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .Alert : .ActionSheet
        let alertController = UIAlertController(title: "Are you sure you want to complete this work order?", message: nil, preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Don't Complete", style: .Default, handler: nil)
        alertController.addAction(cancelAction)

        let completeAction = UIAlertAction(title: "Yes, Complete Work Order", style: .Destructive) { action in
            self.workOrder.complete(
                onSuccess: { statusCode, mappingResult in
                    viewController.tableView.reloadData()
                    self.delegate?.workOrderCreationViewController(self, didCompleteWorkOrder: workOrder)
                },
                onError: { error, statusCode, responseString in
                    viewController.tableView.reloadData()
                }
            )
        }

        alertController.addAction(cancelAction)
        alertController.addAction(completeAction)

        presentViewController(alertController, animated: true)
    }

    // MARK: PDTSimpleCalendarViewControllerDelegate

    func simpleCalendarViewController(controller: PDTSimpleCalendarViewController!, didSelectDate date: NSDate!) {
        workOrder.scheduledStartAt = date.format("yyyy-MM-dd'T'HH:mm:ssZZ")
        isDirty = true
        refreshRightBarButtonItems()
        renderDurationPickerInViewController(controller)
    }

    func simpleCalendarViewController(controller: PDTSimpleCalendarViewController!, isEnabledDate date: NSDate!) -> Bool {
        if let scheduledStartAtDate = workOrder.scheduledStartAtDate {
            return scheduledStartAtDate.atMidnight != date.atMidnight
        }
        return true
    }

    private func renderDurationPickerInViewController(viewController: UIViewController) {
        let calendarViewController = viewController as! CalendarViewController
        let cell = calendarViewController.selectedDateCell

        let durationPickerViewController = UIViewController()
        durationPickerViewController.view.backgroundColor = UIColor.clearColor()
        durationPickerViewController.view.frame.size = CGSize(width: 300.0, height: 100.0)
        durationPickerViewController.modalPresentationStyle = .Popover
        durationPickerViewController.preferredContentSize = durationPickerViewController.view.frame.size
        durationPickerViewController.popoverPresentationController?.sourceView = cell
        durationPickerViewController.popoverPresentationController?.permittedArrowDirections = [.Left, .Right]
        durationPickerViewController.popoverPresentationController?.delegate = self

        let durationPickerView = DurationPickerView()
        durationPickerView.durationPickerViewDelegate = self
        durationPickerView.frame = durationPickerViewController.view.bounds
        durationPickerViewController.view.addSubview(durationPickerView)

        viewController.presentViewController(durationPickerViewController, animated: true)
    }

    // MARK: DurationPickerViewDelegate

    func componentsForDurationPickerView(view: DurationPickerView) -> [CGFloat] {
        var values = [CGFloat]()
        var value: CGFloat = 0.0
        while value < 86400.0 {
            values.append(value)
            value += 900.0 // 15 minutes
        }
        return values
    }

    func componentTitlesForDurationPickerView(view: DurationPickerView) -> [String] {
        var titles = [String]()
        for value in componentsForDurationPickerView(view) {
            let date = NSDate().atMidnight.dateByAddingTimeInterval(NSTimeInterval(value))
            titles.append(date.timeString!)
        }
        return titles
    }

    func durationPickerView(view: DurationPickerView, widthForComponent component: Int) -> CGFloat {
        return 300.0
    }

    func durationPickerView(view: DurationPickerView, didPickDuration duration: CGFloat) {
        workOrder.scheduledStartAt = NSDate.fromString(workOrder.scheduledStartAt).dateByAddingTimeInterval(NSTimeInterval(duration)).format("yyyy-MM-dd'T'HH:mm:ssZZ")
        reloadTableView()

        if workOrder.id == 0 {
            createWorkOrder()
        } else {
            refreshUI()
        }

        if let presentedViewController = presentedViewController {
            if let presentingViewController = presentedViewController.presentingViewController as? UINavigationController {
                presentingViewController.dismissViewController(animated: false)
                presentingViewController.popToRootViewControllerAnimated(true)
            }
        }
    }

    func durationPickerViewInteractionStarted(view: DurationPickerView) {

    }

    func durationPickerViewInteractionEnded(view: DurationPickerView) {

    }

    func durationPickerViewInteractionContinued(view: DurationPickerView) {

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

    // MARK: TaskListViewControllerDelegate

    func jobForTaskListViewController(viewController: TaskListViewController) -> Job! {
        if workOrder.jobId > 0 {
            return JobService.sharedService().jobWithId(workOrder.jobId)
        }
        return nil
    }

    func workOrderForTaskListViewController(viewController: TaskListViewController) -> WorkOrder! {
        return workOrder
    }

    // MARK: WorkOrderTeamViewControllerDelegate

    func workOrderForWorkOrderTeamViewController(viewController: WorkOrderTeamViewController) -> WorkOrder! {
        return workOrder
    }

    func workOrderTeamViewController(viewController: WorkOrderTeamViewController, didUpdateWorkOrderProvider: WorkOrderProvider) {
        workOrder?.reload(
            onSuccess: { statusCode, mappingResult in
                self.reloadTableView()
            },
            onError: { error, statusCode, responseString in
                self.reloadTableView()
            }
        )
    }

    func workOrderTeamViewController(viewController: WorkOrderTeamViewController, didRemoveProvider: Provider) {
        workOrder?.reload(
            onSuccess: { statusCode, mappingResult in
                self.reloadTableView()
            },
            onError: { error, statusCode, responseString in
                self.reloadTableView()
            }
        )
    }

    func flatFeeForNewProvider(provider: Provider, forWorkOrderTeamViewControllerViewController workOrderTeamViewControllerViewController: WorkOrderTeamViewController) -> Double! {
        if let fee = delegate?.flatFeeForNewProvider(provider, forWorkOrderCreationViewController: self) {
            return fee
        }
        return nil
    }

    // MARK: WorkOrderInventoryViewControllerDelegate

    func workOrderForWorkOrderInventoryViewController(viewController: WorkOrderInventoryViewController) -> WorkOrder! {
        return workOrder
    }

    func workOrderInventoryViewController(viewController: WorkOrderInventoryViewController, didUpdateWorkOrderProduct: WorkOrderProduct) {
        workOrder?.reload(
            onSuccess: { statusCode, mappingResult in
                self.reloadTableView()

                if self.workOrder.jobId > 0 {
                    if let job = JobService.sharedService().jobWithId(self.workOrder.jobId) {
                        job.reloadMaterials(
                            { statusCode, mappingResult in

                            },
                            onError: { error, statusCode, responseString in

                            }
                        )
                    }
                }
            },
            onError: { error, statusCode, responseString in
                self.reloadTableView()
            }
        )
    }

    func workOrderInventoryViewController(viewController: WorkOrderInventoryViewController, didRemoveWorkOrderProduct: WorkOrderProduct) {
        workOrder?.reload(["include_estimated_cost": "true", "include_expenses": "true"],
            onSuccess: { statusCode, mappingResult in
                self.reloadTableView()

                if self.workOrder.jobId > 0 {
                    if let job = JobService.sharedService().jobWithId(self.workOrder.jobId) {
                        job.reloadMaterials(
                            { statusCode, mappingResult in

                            },
                            onError: { error, statusCode, responseString in

                            }
                        )
                    }
                }
            },
            onError: { error, statusCode, responseString in
                self.reloadTableView()
            }
        )
    }

    // MARK: UIPopoverPresentationControllerDelegate

    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
}
