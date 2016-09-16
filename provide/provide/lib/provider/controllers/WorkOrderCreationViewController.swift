//
//  WorkOrderCreationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 11/18/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import AVFoundation
import FontAwesomeKit
import KTSwiftExtensions

protocol WorkOrderCreationViewControllerDelegate {
    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, numberOfSectionsInTableView tableView: UITableView) -> Int
    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat
    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, cellForTableView tableView: UITableView, atIndexPath indexPath: IndexPath) -> UITableViewCell!
    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath)
    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, didCreateWorkOrder workOrder: WorkOrder)
    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, didStartWorkOrder workOrder: WorkOrder)
    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, didCancelWorkOrder workOrder: WorkOrder)
    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, didCompleteWorkOrder workOrder: WorkOrder)
    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, didSubmitForApprovalWorkOrder workOrder: WorkOrder)
    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, didApproveWorkOrder workOrder: WorkOrder)
    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, didRejectWorkOrder workOrder: WorkOrder)
    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, didRestartWorkOrder workOrder: WorkOrder)
    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, didCreateExpense expense: Expense)
    func workOrderCreationViewController(_ viewController: WorkOrderCreationViewController, shouldBeDismissedWithWorkOrder workOrder: WorkOrder!)
    func floorplanPinViewForWorkOrderCreationViewController(_ viewController: WorkOrderCreationViewController) -> FloorplanPinView!
    func flatFeeForNewProvider(_ provider: Provider, forWorkOrderCreationViewController viewController: WorkOrderCreationViewController) -> Double!
}

class WorkOrderCreationViewController: WorkOrderDetailsViewController,
                                       CategoryPickerViewControllerDelegate,
                                       CommentsViewControllerDelegate,
                                       DatePickerViewControllerDelegate,
                                       CameraViewControllerDelegate,
                                       ExpenseCaptureViewControllerDelegate,
                                       TaskListViewControllerDelegate,
                                       WorkOrderTeamViewControllerDelegate,
                                       WorkOrderInventoryViewControllerDelegate,
                                       UIPopoverPresentationControllerDelegate {

    var delegate: WorkOrderCreationViewControllerDelegate!

    @IBOutlet fileprivate weak var commentInputToolbar: CommentInputToolbar!

    fileprivate var cancelItem: UIBarButtonItem! {
        let cancelItem = UIBarButtonItem(title: "CANCEL", style: .plain, target: self, action: #selector(WorkOrderCreationViewController.cancel(_:)))
        cancelItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: UIControlState())
        return cancelItem
    }

    fileprivate var dismissItem: UIBarButtonItem! {
        let dismissItem = UIBarButtonItem(title: "DISMISS", style: .plain, target: self, action: #selector(WorkOrderCreationViewController.dismiss(_:)))
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: UIControlState())
        return dismissItem
    }

    fileprivate var cameraItem: UIBarButtonItem! {
        let cameraItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(WorkOrderCreationViewController.camera(_:)))
        cameraItem.isEnabled = ["awaiting_schedule", "scheduled", "in_progress"].index(of: workOrder.status) != nil
        return cameraItem
    }

    fileprivate var taskListItem: UIBarButtonItem! {
        let taskListIconImage = FAKFontAwesome.tasksIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0)).withRenderingMode(.alwaysTemplate)
        let taskListItem = UIBarButtonItem(image: taskListIconImage, style: .plain, target: self, action: #selector(WorkOrderCreationViewController.showTaskList(_:)))
        taskListItem.tintColor = Color.applicationDefaultBarButtonItemTintColor()
        return taskListItem
    }

    fileprivate var activityIndicatorView: UIActivityIndicatorView {
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.startAnimating()
        return activityIndicatorView
    }

    fileprivate var isDirty = false

    fileprivate var reloadingJob = false

    fileprivate var workOrderDetailsHeaderTableViewController: WorkOrderDetailsHeaderTableViewController!

    fileprivate var commentsViewController: CommentsViewController!

    fileprivate var isSaved: Bool {
        if let workOrder = workOrder {
            return workOrder.id > 0
        }
        return false
    }

    fileprivate var isValid: Bool {
        if let workOrder = workOrder {
            let validDate = workOrder.scheduledStartAt != nil
            return validDate
        }
        return false
    }

    func cancel(_ sender: UIBarButtonItem!) {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .alert : .actionSheet
        let alertController = UIAlertController(title: "Are you sure you want to cancel and discard changes?", message: nil, preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Don't Cancel", style: .default, handler: nil)
        alertController.addAction(cancelAction)

        let discardAction = UIAlertAction(title: "Discard", style: .destructive) { [weak self] action in
            self!.delegate?.workOrderCreationViewController(self!, shouldBeDismissedWithWorkOrder: nil)
        }

        alertController.addAction(cancelAction)
        alertController.addAction(discardAction)

        presentViewController(alertController, animated: true)
    }

    func dismiss(_ sender: UIBarButtonItem!) {
        if isDirty {
            let preferredStyle: UIAlertControllerStyle = isIPad() ? .alert : .actionSheet
            let alertController = UIAlertController(title: "Are you sure you want to cancel and discard changes?", message: nil, preferredStyle: preferredStyle)

            let cancelAction = UIAlertAction(title: "Don't Dismiss", style: .default, handler: nil)
            alertController.addAction(cancelAction)

            let discardAction = UIAlertAction(title: "Yes, Discard Pending Changes", style: .destructive) { [weak self] action in
                self!.forceDismiss()
            }

            alertController.addAction(cancelAction)
            alertController.addAction(discardAction)
            
            presentViewController(alertController, animated: true)
        } else {
            forceDismiss()
        }
    }

    fileprivate func forceDismiss() {
        commentInputToolbar.dismiss()
        delegate?.workOrderCreationViewController(self, shouldBeDismissedWithWorkOrder: workOrder)
    }

    func expense(_ sender: UIBarButtonItem!) {
        let expenseCaptureViewController = UIStoryboard("ExpenseCapture").instantiateInitialViewController() as! ExpenseCaptureViewController
        expenseCaptureViewController.modalPresentationStyle = .overCurrentContext
        expenseCaptureViewController.expenseCaptureViewControllerDelegate = self

        presentViewController(expenseCaptureViewController, animated: true)
    }

    func camera(_ sender: UIBarButtonItem!) {
        let cameraViewController = UIStoryboard("Camera").instantiateInitialViewController() as! CameraViewController
        cameraViewController.delegate = self
        
        presentViewController(cameraViewController, animated: true)
    }

    func createWorkOrder(_ sender: AnyObject!) {
        createWorkOrder()
    }

    func createWorkOrder() {
        navigationItem.titleView = activityIndicatorView

        workOrder.save(
            { statusCode, mappingResult in
                self.isDirty = false
                if statusCode == 201 {
                    let wo = mappingResult?.firstObject as! WorkOrder
                    self.workOrder.status = wo.status
                    self.reloadTableView(true)
                    self.delegate?.workOrderCreationViewController(self, didCreateWorkOrder: self.workOrder)
                    self.reloadComments()
                }
                self.refreshUI()
            },
            onError: { error, statusCode, responseString in
                self.refreshUI()
            }
        )
    }

    fileprivate func refreshUI() {
        commentInputToolbar?.clipToBounds(view.bounds)

        refreshTitle()
        refreshLeftBarButtonItems()
        refreshRightBarButtonItems()

        reloadTableView(true)

        if workOrder.allowNewComments {
            commentInputToolbar?.enable()
        } else {
            commentInputToolbar?.disable()
        }

        if workOrder.categoryId == 0 {
            presentCategoryPickerViewController()
        }
    }

    fileprivate func presentCategoryPickerViewController(_ animated: Bool = true) {
        let viewController = UIStoryboard("CategoryPicker").instantiateViewController(withIdentifier: "CategoryPickerViewController")
        (viewController as! CategoryPickerViewController).delegate = self
        CategoryService.sharedService().fetch(companyId: workOrder.companyId,
            onCategoriesFetched: { categories in
                (viewController as! CategoryPickerViewController).categories = categories

                if let selectedCategory = self.workOrder.category {
                    (viewController as! CategoryPickerViewController).selectedCategories = [selectedCategory]
                    viewController.navigationItem.hidesBackButton = false
                } else {
                    viewController.navigationItem.hidesBackButton = true
                }
            }
        )
        viewController.navigationItem.hidesBackButton = true
        //presentViewController(viewController, animated: false)
        navigationController!.pushViewController(viewController, animated: false)
    }

    fileprivate func refreshTitle() {
        navigationItem.title = title == nil ? (workOrder?.category != nil ? workOrder?.category.name : workOrder?.customer.contact.name) : title
        navigationItem.titleView = nil
    }

    fileprivate func refreshLeftBarButtonItems() {
        if isSaved {
            navigationItem.leftBarButtonItems = [dismissItem]
        } else {
            navigationItem.leftBarButtonItems = [cancelItem]
        }
    }

    fileprivate func refreshRightBarButtonItems() {
        if isValid && isDirty {
            navigationItem.rightBarButtonItems = []
        } else {
            navigationItem.rightBarButtonItems = []
        }

        if isSaved {
            navigationItem.rightBarButtonItems!.append(taskListItem)
        }
    }

    func showTaskList(_ sender: UIBarButtonItem) {
        let taskListNavigationController = UIStoryboard("TaskList").instantiateInitialViewController() as! UINavigationController
        (taskListNavigationController.viewControllers.first! as! TaskListViewController).taskListViewControllerDelegate = self
        taskListNavigationController.modalPresentationStyle = .popover
        taskListNavigationController.preferredContentSize = CGSize(width: 300, height: 250)
        taskListNavigationController.popoverPresentationController!.barButtonItem = sender
        taskListNavigationController.popoverPresentationController!.permittedArrowDirections = [.right]
        taskListNavigationController.popoverPresentationController!.canOverlapSourceViewRect = false
        presentViewController(taskListNavigationController, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "WORK ORDER", style: .plain, target: nil, action: nil)

        NotificationCenter.default.addObserverForName("WorkOrderChanged") { notification in
            if let workOrder = notification.object as? WorkOrder {
                if let wo = self.workOrder {
                    if workOrder.id == wo.id {
                        self.workOrder = workOrder
                    }
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        dispatch_after_delay(0.0) {
            self.refreshUI()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier! == "WorkOrderDetailsHeaderTableViewControllerEmbedSegue" {
            workOrderDetailsHeaderTableViewController = segue.destination as! WorkOrderDetailsHeaderTableViewController
        } else if segue.identifier! == "WorkOrderTeamViewControllerEmbedSegue" {
            (segue.destination as! WorkOrderTeamViewController).delegate = self
        } else if segue.identifier! == "CommentsViewControllerEmbedSegue" {
            commentsViewController = segue.destination as! CommentsViewController
            commentsViewController.commentsViewControllerDelegate = self
            commentInputToolbar?.commentsViewController = commentsViewController
        }
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let height = delegate?.workOrderCreationViewController(self, tableView: tableView, heightForRowAtIndexPath: indexPath) {
            return height
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        if let sectionCount = delegate?.workOrderCreationViewController(self, numberOfSectionsInTableView: tableView) {
            return sectionCount
        }
        return super.numberOfSections(in: tableView)
    }

    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let rowCount = delegate?.workOrderCreationViewController(self, tableView: tableView, numberOfRowsInSection: section) {
            return rowCount
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!

        if let c = delegate?.workOrderCreationViewController(self, cellForTableView: tableView, atIndexPath: indexPath) {
            cell = c
        } else {
            cell = super.tableView(tableView, cellForRowAt: indexPath)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return tableView.cellForRow(at: indexPath)?.accessoryType == .disclosureIndicator
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if tableView.cellForRow(at: indexPath)?.accessoryType == .disclosureIndicator {
            return indexPath
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let delegate = delegate {
            delegate.workOrderCreationViewController(self, tableView: tableView, didSelectRowAtIndexPath: indexPath)
        } else {
            super.tableView(tableView, didSelectRowAt: indexPath)
        }
    }

    // MARK: WorkOrderDetailsHeaderTableViewControllerDelegate

    override func workOrderCreationViewControllerForDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController) -> WorkOrderCreationViewController! {
        return self
    }

    override func workOrderDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController, shouldStartWorkOrder workOrder: WorkOrder) {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .alert : .actionSheet
        let alertController = UIAlertController(title: "Are you sure you want to start this work order?", message: "This cannot be undone.", preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Don't Start", style: .default, handler: nil)
        alertController.addAction(cancelAction)

        let startAction = UIAlertAction(title: "Yes, Manually Start Work Order", style: .destructive) { action in
            self.workOrder.arrive(
                { statusCode, mappingResult in
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

    override func workOrderDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController, shouldCancelWorkOrder workOrder: WorkOrder) {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .alert : .actionSheet
        let alertController = UIAlertController(title: "Are you sure you want to cancel this work order?", message: "This cannot be undone.", preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Don't Cancel", style: .default, handler: nil)
        alertController.addAction(cancelAction)

        let cancelWorkOrderAction = UIAlertAction(title: "Yes, Cancel Work Order", style: .destructive) { action in
            self.workOrder.cancel(
                { statusCode, mappingResult in
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

    override func workOrderDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController, shouldCompleteWorkOrder workOrder: WorkOrder) {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .alert : .actionSheet
        let alertController = UIAlertController(title: "Are you sure you want to complete this work order?", message: nil, preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Don't Complete", style: .default, handler: nil)
        alertController.addAction(cancelAction)

        let completeAction = UIAlertAction(title: "Yes, Complete Work Order", style: .destructive) { action in
            self.workOrder.complete(
                { statusCode, mappingResult in
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

    override func workOrderDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController, shouldSubmitForApprovalWorkOrder workOrder: WorkOrder) {
        self.workOrder.submitForApproval(
            { statusCode, mappingResult in
                viewController.tableView.reloadData()
                self.delegate?.workOrderCreationViewController(self, didSubmitForApprovalWorkOrder: workOrder)
            },
            onError: { error, statusCode, responseString in
                viewController.tableView.reloadData()
            }
        )
    }

    override func workOrderDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController, shouldApproveWorkOrder workOrder: WorkOrder) {
        self.workOrder.approve(
            { statusCode, mappingResult in
                viewController.tableView.reloadData()
                self.delegate?.workOrderCreationViewController(self, didApproveWorkOrder: workOrder)
            },
            onError: { error, statusCode, responseString in
                viewController.tableView.reloadData()
            }
        )
    }

    override func workOrderDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController, shouldRejectWorkOrder workOrder: WorkOrder) {
        self.workOrder.reject(
            { statusCode, mappingResult in
                viewController.tableView.reloadData()
                self.delegate?.workOrderCreationViewController(self, didRejectWorkOrder: workOrder)
            },
            onError: { error, statusCode, responseString in
                viewController.tableView.reloadData()
            }
        )
    }

    override func workOrderDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController, shouldRestartWorkOrder workOrder: WorkOrder) {
        self.workOrder.restart(
            { statusCode, mappingResult in
                viewController.tableView.reloadData()
                self.delegate?.workOrderCreationViewController(self, didRestartWorkOrder: workOrder)
            },
            onError: { error, statusCode, responseString in
                viewController.tableView.reloadData()
            }
        )
    }

    override func reloadTableView() {
        super.reloadTableView()

        reloadTableView(true)
    }

    fileprivate func reloadTableView(_ reloadComments: Bool = true) {
        if reloadComments {
            if let _ = commentsViewController {
                self.reloadComments()
            }
        }

        if let workOrderDetailsHeaderTableViewController = workOrderDetailsHeaderTableViewController {
            workOrderDetailsHeaderTableViewController.reloadTableView()
        }
    }

    // MARK: DatePickerViewControllerDelegate

    func datePickerViewController(_ viewController: DatePickerViewController, requiresDateAfter refDate: Date) -> Bool {
        return refDate.timeIntervalSinceNow < 0
    }

    func datePickerViewController(_ viewController: DatePickerViewController, didSetDate date: Date) {
        if date.timeIntervalSinceNow <= 0 {
            showToast("Select a date in the future.", dismissAfter: 3.0)
            return
        }

        if let fieldName = viewController.fieldName {
            let _ = navigationController?.popViewController(animated: true)

            if fieldName == "scheduledStartAt" {
                workOrder.scheduledStartAt = date.format("yyyy-MM-dd'T'HH:mm:ssZZ")
                isDirty = true
            } else if fieldName == "dueAt" {
                workOrder.dueAt = date.format("yyyy-MM-dd'T'HH:mm:ssZZ")
                isDirty = true
            }

            refreshRightBarButtonItems()

            if workOrder.status == "awaiting_schedule" && workOrder.scheduledStartAt != nil {
                workOrder.status = "scheduled"
            }

            // FIXME-- make this support the end date also
            // FIXME-- WTF was this?? workOrder.scheduledStartAt = NSDate.fromString(workOrder.scheduledStartAt).dateByAddingTimeInterval(NSTimeInterval(duration)).format("yyyy-MM-dd'T'HH:mm:ssZZ")

            reloadTableView(true)

            if workOrder.id == 0 {
                createWorkOrder()
            } else {
                workOrder.save(
                    { statusCode, mappingResult in
                        self.isDirty = false
                        self.refreshUI()
                    },
                    onError: { error, statusCode, responseString in
                        self.refreshUI()
                    }
                )

                refreshUI()
            }
        }
    }

    // MARK: CategoryPickerViewControllerDelegate

    func categoryPickerViewController(_ viewController: CategoryPickerViewController, didSelectCategory category: Category) {
        if workOrder.id == 0 {
            workOrder.category = category
            workOrder.categoryId = category.id
            reloadTableView(true)

            if let navigationController = viewController.navigationController {
                navigationController.popViewController(animated: false)
            }

            //dismissViewController(animated: true)

            if let floorplanPinViewForWorkOrderCreationViewController = delegate?.floorplanPinViewForWorkOrderCreationViewController(self) {
                floorplanPinViewForWorkOrderCreationViewController.category = category
            }
        }
    }

    // MARK: CommentsViewControllerDelegate

    func queryParamsForCommentsViewController(_ viewController: CommentsViewController) -> [String : AnyObject]! {
        return [String : AnyObject]()
    }

    func commentableTypeForCommentsViewController(_ viewController: CommentsViewController) -> String {
        return "work_order"
    }

    func commentableIdForCommentsViewController(_ viewController: CommentsViewController) -> Int {
        return workOrder.id
    }

    func commentsViewController(_ viewController: CommentsViewController, shouldCreateComment comment: String, withImageAttachment image: UIImage! = nil) {
        if let workOrder = workOrder {
            workOrder.addComment(comment,
                onSuccess: { statusCode, mappingResult in
                    let newComment = mappingResult?.firstObject as! Comment

                    if let image = image {
                        let data = UIImageJPEGRepresentation(image, 1.0)!

                        ApiService.sharedService().addAttachment(data,
                            withMimeType: "image/jpg",
                            toCommentWithId: String(newComment.id),
                            forCommentableType: "work_order",
                            withCommentableId: String(workOrder.id),
                            params: [:],
                            onSuccess: { statusCode, attachmentMappingResult in
                                newComment.attachments.append(attachmentMappingResult?.firstObject as! Attachment)

                                dispatch_after_delay(0.0) {
                                    viewController.addComment(newComment)
                                }
                            },
                            onError: { error, statusCode, responseString in
                                // TODO: implement
                            }
                        )
                    } else {
                        dispatch_after_delay(0.0) {
                            viewController.addComment(newComment)
                        }
                    }
                },
                onError: { error, statusCode, responseString in

                }
            )
        }
    }

    fileprivate func reloadComments() {
        if commentsViewController == nil {
            return
        }

        commentsViewController.reset()
    }

    // MARK: CameraViewControllerDelegate

    func outputModeForCameraViewController(_ viewController: CameraViewController) -> CameraOutputMode {
        return .photo
    }

    func cameraViewControllerDidBeginAsyncStillImageCapture(_ viewController: CameraViewController) {
        cameraViewControllerCanceled(viewController)
    }

    func cameraViewController(_ viewController: CameraViewController, didCaptureStillImage image: UIImage) {
        navigationItem.titleView = activityIndicatorView

        let tags = ["photo"]
        var params: [String : AnyObject] = [
            "tags": tags as AnyObject,
        ]

        if let location = LocationService.sharedService().currentLocation {
            params["latitude"] = location.coordinate.latitude as AnyObject?
            params["longitude"] = location.coordinate.longitude as AnyObject?
        }

        workOrder.attach(image, params: params,
            onSuccess: { (statusCode, mappingResult) -> () in
                self.refreshUI()
                self.reloadTableView(true)
            },
            onError: { (error, statusCode, responseString) -> () in
                self.refreshUI()
            }
        )
    }

    func cameraViewControllerCanceled(_ viewController: CameraViewController) {
        dismissViewController(false)
    }

    func cameraViewController(_ viewController: CameraViewController, didSelectImageFromCameraRoll image: UIImage) {

    }

    func cameraViewControllerDidOutputFaceMetadata(_ viewController: CameraViewController, metadataFaceObject: AVMetadataFaceObject) {

    }

    func cameraViewControllerShouldOutputFaceMetadata(_ viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerShouldRenderFacialRecognition(_ viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerShouldOutputOCRMetadata(_ viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewController(_ cameraViewController: CameraViewController, didStartVideoCaptureAtURL fileURL: URL) {

    }
    
    func cameraViewController(_ cameraViewController: CameraViewController, didFinishVideoCaptureAtURL fileURL: URL) {
        
    }

    func cameraViewController(_ viewController: CameraViewController, didRecognizeText text: String!) {

    }

    override func navigationControllerBackItemTitleForManifestViewController(_ viewController: UIViewController) -> String! {
        return navigationItem.title
    }

    // MARK: ExpenseCaptureViewControllerDelegate
    
    func expensableForExpenseCaptureViewController(_ viewController: ExpenseCaptureViewController) -> Model {
        return workOrder
    }

    func expenseCaptureViewControllerBeganCreatingExpense(_ viewController: ExpenseCaptureViewController) {

    }

    func expenseCaptureViewController(_ viewController: ExpenseCaptureViewController, didCaptureReceipt receipt: UIImage, recognizedTexts texts: [String]!) {
        navigationItem.titleView = activityIndicatorView
    }

    func expenseCaptureViewController(_ viewController: ExpenseCaptureViewController, didCreateExpense expense: Expense) {
        refreshUI()
        delegate?.workOrderCreationViewController(self, didCreateExpense: expense)
    }

    // MARK: TaskListViewControllerDelegate

    func jobForTaskListViewController(_ viewController: TaskListViewController) -> Job! {
        if workOrder.jobId > 0 {
            return JobService.sharedService().jobWithId(workOrder.jobId)
        }
        return nil
    }

    func workOrderForTaskListViewController(_ viewController: TaskListViewController) -> WorkOrder! {
        return workOrder
    }

    // MARK: WorkOrderTeamViewControllerDelegate

    func workOrderForWorkOrderTeamViewController(_ viewController: WorkOrderTeamViewController) -> WorkOrder! {
        return workOrder
    }

    func workOrderTeamViewController(_ viewController: WorkOrderTeamViewController, didUpdateWorkOrderProvider: WorkOrderProvider) {
        workOrder?.reload(
            { statusCode, mappingResult in
                self.reloadTableView(true)
            },
            onError: { error, statusCode, responseString in
                self.reloadTableView(true)
            }
        )
    }

    func workOrderTeamViewController(_ viewController: WorkOrderTeamViewController, didRemoveProvider: Provider) {
        workOrder?.reload(
            { statusCode, mappingResult in
                self.reloadTableView(true)
            },
            onError: { error, statusCode, responseString in
                self.reloadTableView(true)
            }
        )
    }

    func flatFeeForNewProvider(_ provider: Provider, forWorkOrderTeamViewControllerViewController workOrderTeamViewControllerViewController: WorkOrderTeamViewController) -> Double! {
        if let fee = delegate?.flatFeeForNewProvider(provider, forWorkOrderCreationViewController: self) {
            return fee
        }
        return nil
    }

    // MARK: WorkOrderInventoryViewControllerDelegate

    func workOrderForWorkOrderInventoryViewController(_ viewController: WorkOrderInventoryViewController) -> WorkOrder! {
        return workOrder
    }

    func workOrderInventoryViewController(_ viewController: WorkOrderInventoryViewController, didUpdateWorkOrderProduct: WorkOrderProduct) {
        workOrder?.reload(
            { statusCode, mappingResult in
                self.reloadTableView(true)

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
                self.reloadTableView(true)
            }
        )
    }

    func workOrderInventoryViewController(_ viewController: WorkOrderInventoryViewController, didRemoveWorkOrderProduct: WorkOrderProduct) {
        workOrder?.reload(["include_estimated_cost": "false" as AnyObject, "include_expenses": "false" as AnyObject],
            onSuccess: { statusCode, mappingResult in
                self.reloadTableView(true)

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
                self.reloadTableView(true)
            }
        )
    }

    // MARK: UIPopoverPresentationControllerDelegate

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
