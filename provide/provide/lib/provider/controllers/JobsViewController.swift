//
//  JobsViewController.swift
//  provide
//
//  Created by Kyle Thomas on 11/17/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class JobsViewController: ViewController,
                          UITableViewDelegate,
                          UITableViewDataSource,
                          UIPopoverPresentationControllerDelegate,
                          JobCreationViewControllerDelegate,
                          DraggableViewGestureRecognizerDelegate {

    @IBOutlet private weak var addJobBarButtonItem: UIBarButtonItem! {
        didSet {
            if let addJobBarButtonItem = addJobBarButtonItem {
                addJobBarButtonItem.tintColor = UIColor.whiteColor()
            }
        }
    }
    @IBOutlet private var tableView: UITableView!

    private var page = 1
    private let rpp = 10
    private var lastJobIndex = -1

    private var refreshControl: UIRefreshControl!

    private weak var jobCreationViewController: JobCreationViewController!

    private var cancellingJob = false

    private var jobs = [Job]() {
        didSet {
            tableView?.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "JOBS"

        setupPullToRefresh()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "JobViewControllerSegue" {
            if let sender = sender {
                (segue.destinationViewController as! JobViewController).job = (sender as! JobTableViewCell).job
            }
        } else if segue.identifier == "JobWizardTabBarControllerSegue" {
            if let sender = sender {
                (segue.destinationViewController as! JobWizardTabBarController).job = (sender as! JobTableViewCell).job
            }
        } else if segue.identifier == "JobCreationViewControllerPopoverSegue" {
            let navigationController = segue.destinationViewController as! UINavigationController
            navigationController.preferredContentSize = CGSizeMake(view.frame.width * 0.6, 425)
            navigationController.popoverPresentationController!.delegate = self

            jobCreationViewController = navigationController.viewControllers.first! as! JobCreationViewController
            jobCreationViewController.delegate = self

        }
    }

    private func setupPullToRefresh() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "reset", forControlEvents: .ValueChanged)

        tableView.addSubview(refreshControl)
        tableView.alwaysBounceVertical = true

        refresh()
    }

    func reset() {
        jobs = [Job]()
        page = 1
        lastJobIndex = -1
        refresh()
    }

    func refresh() {
        if page == 1 {
            refreshControl.beginRefreshing()
        }

        var params: [String : AnyObject] = [
            "page": page,
            "rpp": rpp,
            "status": "configuring,in_progress,pending_completion",
            "include_customer": "true",
            "include_expenses": "true",
            "include_products": "true",
        ]

        if let defaultCompanyId = ApiService.sharedService().defaultCompanyId {
            params["company_id"] = defaultCompanyId
        }

        ApiService.sharedService().fetchJobs(params,
            onSuccess: { statusCode, mappingResult in
                let fetchedJobs = mappingResult.array() as! [Job]
                self.jobs += fetchedJobs

                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            },
            onError: { error, statusCode, responseString in
                // TODO
            }
        )
    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return jobs.count
    }

    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("jobsTableViewCellReuseIdentifier", forIndexPath: indexPath) as! JobTableViewCell
        cell.job = jobs[indexPath.row]

//        if let gestureRecognizers = cell.containerView.gestureRecognizers {
//            for gestureRecognizer in gestureRecognizers {
//                if gestureRecognizer.isKindOfClass(JobTableViewCellGestureRecognizer) {
//                    cell.containerView.removeGestureRecognizer(gestureRecognizer)
//                }
//            }
//        }
//
//        let gestureRecognizer = JobTableViewCellGestureRecognizer(viewController: self)
//        gestureRecognizer.draggableViewGestureRecognizerDelegate = self
//        cell.containerView.addGestureRecognizer(gestureRecognizer)

        return cell
    }

//    @available(iOS 2.0, *)
//    optional public func numberOfSectionsInTableView(tableView: UITableView) -> Int // Default is 1 if not implemented
//
//    @available(iOS 2.0, *)
//    optional public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? // fixed font style. use custom view (UILabel) if you want something different
//    @available(iOS 2.0, *)
//    optional public func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String?
//
//    // Editing
//
//    // Individual rows can opt out of having the -editing property set for them. If not implemented, all rows are assumed to be editable.
//    @available(iOS 2.0, *)

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
//
//    // Moving/reordering
//
//    // Allows the reorder accessory view to optionally be shown for a particular row. By default, the reorder control will be shown only if the datasource implements -tableView:moveRowAtIndexPath:toIndexPath:
//    @available(iOS 2.0, *)
//    optional public func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool
//
//    // Index
//
//    @available(iOS 2.0, *)
//    optional public func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? // return list of section titles to display in section index view (e.g. "ABCD...Z#")
//    @available(iOS 2.0, *)
//    optional public func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int // tell table which section corresponds to section title/index (e.g. "B",1))
//
//    // Data manipulation - insert and delete support
//
//    // After a row has the minus or plus button invoked (based on the UITableViewCellEditingStyle for the cell), the dataSource must commit the change
//    // Not called for edit actions using UITableViewRowAction - the action's handler will be invoked instead
//    @available(iOS 2.0, *)
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            cancelJobAtIndexPath(indexPath)
        }
    }

    func cancelJobAtIndexPath(indexPath: NSIndexPath) {
        let job = jobs[indexPath.row]
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? JobTableViewCell {
            if ["canceled", "completed"].indexOf(job.status) == nil {
                //cell.dismiss()
                promptForJobCancellation(job, cell: cell)
            }
        }
    }

    func promptForJobCancellation(job: Job, cell: JobTableViewCell) {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .Alert : .ActionSheet
        let alertController = UIAlertController(title: "Are you sure you want to cancel this job?", message: nil, preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "No, Don't Cancel", style: .Cancel) { action in
            cell.reset()
        }
        alertController.addAction(cancelAction)

        let setCancelJobAction = UIAlertAction(title: "Cancel Job", style: .Destructive) { action in
            job.cancel(
                onSuccess: { [weak self] statusCode, mappingResult in
                    self!.tableView?.beginUpdates()
                    self!.jobs.removeObject(job)
                    self!.tableView?.deleteRowsAtIndexPaths([self!.tableView.indexPathForCell(cell)!], withRowAnimation: .Fade)
                    self!.tableView?.endUpdates()
                },
                onError: { error, statusCode, responseString in

                }
            )
        }
        alertController.addAction(setCancelJobAction)

        presentViewController(alertController, animated: true)
    }
//
//    // Data manipulation - reorder / moving support
//
//    @available(iOS 2.0, *)
//    optional public func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath)

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let jobIndex = indexPath.row
        if jobIndex == jobs.count - 1 && jobIndex > lastJobIndex {
            page++
            lastJobIndex = jobIndex
            refresh()
        }
    }

//    @available(iOS 6.0, *)
//    optional public func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
//    @available(iOS 6.0, *)
//    optional public func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int)
//    @available(iOS 6.0, *)
//    optional public func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
//    @available(iOS 6.0, *)
//    optional public func tableView(tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int)
//    @available(iOS 6.0, *)
//    optional public func tableView(tableView: UITableView, didEndDisplayingFooterView view: UIView, forSection section: Int)
//
//    // Variable height support
//
//    @available(iOS 2.0, *)
//    optional public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
//    @available(iOS 2.0, *)
//    optional public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
//    @available(iOS 2.0, *)
//    optional public func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
//
//    // Use the estimatedHeight methods to quickly calcuate guessed values which will allow for fast load times of the table.
//    // If these methods are implemented, the above -tableView:heightForXXX calls will be deferred until views are ready to be displayed, so more expensive logic can be placed there.
//    @available(iOS 7.0, *)
//    optional public func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
//    @available(iOS 7.0, *)
//    optional public func tableView(tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat
//    @available(iOS 7.0, *)
//    optional public func tableView(tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat
//
//    // Section header & footer information. Views are preferred over title should you decide to provide both
//
//    @available(iOS 2.0, *)
//    optional public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? // custom view for header. will be adjusted to default or specified header height
//    @available(iOS 2.0, *)
//    optional public func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? // custom view for footer. will be adjusted to default or specified footer height
//
//    // Accessories (disclosures).
//
//    @available(iOS 2.0, *)
//    optional public func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath)
//
//    // Selection
//
//    // -tableView:shouldHighlightRowAtIndexPath: is called when a touch comes down on a row.
//    // Returning NO to that message halts the selection process and does not cause the currently selected row to lose its selected look while the touch is down.
//    @available(iOS 6.0, *)
//    optional public func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool
//    @available(iOS 6.0, *)
//    optional public func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath)
//    @available(iOS 6.0, *)
//    optional public func tableView(tableView: UITableView, didUnhighlightRowAtIndexPath indexPath: NSIndexPath)
//
//    // Called before the user changes the selection. Return a new indexPath, or nil, to change the proposed selection.
//    @available(iOS 2.0, *)
//    optional public func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath?
//    @available(iOS 3.0, *)
//    optional public func tableView(tableView: UITableView, willDeselectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath?

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

//    @available(iOS 3.0, *)
//    optional public func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath)
//
//    // Editing
//
//    // Allows customization of the editingStyle for a particular cell located at 'indexPath'. If not implemented, all editable cells will have UITableViewCellEditingStyleDelete set for them when the table has editing property set to YES.
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
    }
//    @available(iOS 3.0, *)
//    optional public func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String?
//    @available(iOS 8.0, *)
//    optional public func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? // supercedes -tableView:titleForDeleteConfirmationButtonForRowAtIndexPath: if return value is non-nil
//
//    // Controls whether the background is indented while editing.  If not implemented, the default is YES.  This is unrelated to the indentation level below.  This method only applies to grouped style table views.
//    @available(iOS 2.0, *)
//    optional public func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool
//
//    // The willBegin/didEnd methods are called whenever the 'editing' property is automatically changed by the table (allowing insert/delete/move). This is done by a swipe activating a single row
//    @available(iOS 2.0, *)
//    optional public func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath indexPath: NSIndexPath)
//    @available(iOS 2.0, *)
//    optional public func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath)
//
//    // Moving/reordering
//
//    // Allows customization of the target row for a particular row as it is being moved/reordered
//    @available(iOS 2.0, *)
//    optional public func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath
//
//    // Indentation
//
//    @available(iOS 2.0, *)
//    optional public func tableView(tableView: UITableView, indentationLevelForRowAtIndexPath indexPath: NSIndexPath) -> Int // return 'depth' of row for hierarchies
//
//    // Copy/Paste.  All three methods must be implemented by the delegate.
//
//    @available(iOS 5.0, *)
//    optional public func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool
//    @available(iOS 5.0, *)
//    optional public func tableView(tableView: UITableView, canPerformAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool
//    @available(iOS 5.0, *)
//    optional public func tableView(tableView: UITableView, performAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?)
//
//    // Focus
//
//    @available(iOS 9.0, *)
//    optional public func tableView(tableView: UITableView, canFocusRowAtIndexPath indexPath: NSIndexPath) -> Bool
//    @available(iOS 9.0, *)
//    optional public func tableView(tableView: UITableView, shouldUpdateFocusInContext context: UITableViewFocusUpdateContext) -> Bool
//    @available(iOS 9.0, *)
//    optional public func tableView(tableView: UITableView, didUpdateFocusInContext context: UITableViewFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator)
//    @available(iOS 9.0, *)
//    optional public func indexPathForPreferredFocusedViewInTableView(tableView: UITableView) -> NSIndexPath?

    // MARK: JobCreationViewControllerDelegate

    func jobCreationViewController(viewController: JobCreationViewController, didCreateJob job: Job) {
        jobs.insert(job, atIndex: 0)

        if let jobCreationViewController = jobCreationViewController {
            jobCreationViewController.presentingViewController?.dismissViewController(animated: true)
        }

        // HACK
        let jobCreationTableViewCell = JobTableViewCell(frame: CGRectZero)
        jobCreationTableViewCell.job = job
        performSegueWithIdentifier("JobWizardTabBarControllerSegue", sender: jobCreationTableViewCell)
    }

    // MARK: DraggableViewGestureRecognizerDelegate

    func draggableViewGestureRecognizer(gestureRecognizer: DraggableViewGestureRecognizer, shouldResetView view: UIView) -> Bool {
        return false
    }

    func draggableViewGestureRecognizer(gestureRecognizer: DraggableViewGestureRecognizer, shouldAnimateResetView view: UIView) -> Bool {
//        if gestureRecognizer.isKindOfClass(JobTableViewCell) {
//            return (gestureRecognizer as! JobTableViewCellGestureRecognizer).shouldAnimateViewReset
//        }
        return false
    }

    func jobsTableViewCellGestureRecognized(gestureRecognizer: UIGestureRecognizer) {
        // no-op
    }

    private class JobTableViewCellGestureRecognizer: DraggableViewGestureRecognizer {

        private weak var tableView: UITableView! {
            return jobsViewController?.tableView
        }

        private weak var jobsViewController: JobsViewController!

        private var initialBackgroundColor: UIColor!

        private var shouldCancelJob = false

//        private var window: UIWindow! {
//            return UIApplication.sharedApplication().keyWindow!
//        }

//        var shouldAnimateViewReset: Bool {
//            return !shouldCancelJob
//        }

        init(viewController: JobsViewController) {
            super.init(target: viewController, action: "jobsTableViewCellGestureRecognized:")
            jobsViewController = viewController
        }

        override private var initialView: UIView! {
            didSet {
                if let initialView = initialView {
                    if initialView.superview!.isKindOfClass(JobTableViewCell) {
//                        tableView = initialView.superview! as! UITableView
//                        tableView?.scrollEnabled = false

                        //initialView.frame = tableView.convertRect(initialView.frame, toView: nil)

//                        window.addSubview(initialView)
//                        window.bringSubviewToFront(initialView)
                    }
                } else if let _ = oldValue {
                    //supervisorsPickerCollectionView.backgroundColor = initialSupervisorsPickerCollectionViewBackgroundColor

//                    tableView?.scrollEnabled = true
//                    tableView = nil

                    shouldCancelJob = false
                }
            }
        }

        private func dismissCell() {
            if let tableViewCell = initialView.superview?.superview as? JobTableViewCell {
                tableViewCell.dismiss()
            }
        }

        private func restoreCell() {
            if let tableViewCell = initialView.superview?.superview as? JobTableViewCell {
                tableViewCell.reset()
            }
        }

        private override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
            let cell = initialView.superview!.superview! as! JobTableViewCell
            let indexPath = tableView.indexPathForCell(cell)!
            let selected = abs(initialView.frame.origin.x) <= 5.0

            if shouldCancelJob {
                jobsViewController?.cancelJobAtIndexPath(indexPath)
            } else {
                restoreCell()
            }

            super.touchesEnded(touches, withEvent: event)

            if selected {
                dispatch_after_delay(0.0) { [weak self] in
                    self!.tableView?.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
                    self!.jobsViewController?.performSegueWithIdentifier("JobWizardTabBarControllerSegue", sender: cell)
                    cell.setHighlighted(false, animated: true)
                    cell.setSelected(false, animated: true)
                }
            }
        }

        private override func drag(xOffset: CGFloat, yOffset: CGFloat) {
            var newFrame = CGRect(origin: initialView.frame.origin, size: initialView.frame.size)
            newFrame.origin.x += xOffset

            initialView.frame = newFrame

            if initialView == nil || tableView == nil {
                return
            }

            //let tableViewFrame = tableView.superview!.convertRect(supervisorsPickerCollectionView.frame, toView: nil)
            let cancelStrength = abs(initialView.frame.origin.x) / initialView.frame.width
            let isCancelSwipeDirection = initialView.frame.origin.x < 0.0
            shouldCancelJob = !jobsViewController.cancellingJob && cancelStrength >= 0.25 && isCancelSwipeDirection

            if isCancelSwipeDirection {
                initialView.backgroundColor = Color.abandonedStatusColor().colorWithAlphaComponent(cancelStrength / 0.75)
            }

            if shouldCancelJob {
                //let accessoryImage = FAKFontAwesome.removeIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0)).imageWithRenderingMode(.AlwaysTemplate)
                //(initialView as! JobTableViewCell).setAccessoryImage(accessoryImage, tintColor: Color.abandonedStatusColor())
            } else {
                //restoreCell()
                //(initialView as! JobTableViewCell).accessoryImage = nil
            }
        }
    }

    deinit {
        print("deinitialized jobs view controller")
    }
}
