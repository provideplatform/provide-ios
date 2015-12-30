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
                          JobTableViewCellDelegate,
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
                let job = (sender as! JobTableViewCell).job

                let cacheAge = job.timeIntervalSinceLastRefreshDate()
                if cacheAge >= 0.0 {
                    if cacheAge > 60.0 {
                        job.reload(
                            onSuccess: { statusCode, mappingResult in
                                if let job = mappingResult.firstObject as? Job {
                                    var index: Int?
                                    for j in self.jobs {
                                        if j.id == job.id {
                                            index = self.jobs.indexOfObject(j)
                                        }
                                    }

                                    if let index = index {
                                        self.jobs.replaceRange(index...index, with: [job])
                                    }

                                    (segue.destinationViewController as! JobWizardTabBarController).job = job
                                }
                            },
                            onError: { error, statusCode, responseString in

                            }
                        )
                    } else {
                        (segue.destinationViewController as! JobWizardTabBarController).job = job
                    }
                }
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

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("jobsTableViewCellReuseIdentifier", forIndexPath: indexPath) as! JobTableViewCell
        cell.jobTableViewCellDelegate = self
        cell.job = jobs[indexPath.row]
        return cell
    }

    func cancelJobAtIndexPath(indexPath: NSIndexPath) {
        let job = jobs[indexPath.row]
        if let cell = tableView.cellForRowAtIndexPath(indexPath) as? JobTableViewCell {
            if ["canceled", "completed"].indexOf(job.status) == nil {
                cell.dismiss()
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

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let jobIndex = indexPath.row
        if jobIndex == jobs.count - 1 && jobIndex > lastJobIndex {
            page++
            lastJobIndex = jobIndex
            refresh()
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        performSegueWithIdentifier("JobWizardTabBarControllerSegue", sender: cell)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    // MARK: JobCreationViewControllerDelegate

    func jobCreationViewController(viewController: JobCreationViewController, didCreateJob job: Job) {
        jobs.insert(job, atIndex: 0)

        if let jobCreationViewController = jobCreationViewController {
            jobCreationViewController.presentingViewController?.dismissViewController(animated: true)
        }

        // HACK
        let jobCreationTableViewCell = JobTableViewCell(coder: NSCoder())
        jobCreationTableViewCell!.job = job
        performSegueWithIdentifier("JobWizardTabBarControllerSegue", sender: jobCreationTableViewCell)
    }

    // MARK: JobTableViewCellDelegate

    func jobTableViewCell(tableViewCell: JobTableViewCell, shouldCancelJob job: Job) {
        for j in jobs {
            if j.id == job.id {
                let indexPath = NSIndexPath(forRow: jobs.indexOfObject(j)!, inSection: 0)
                cancelJobAtIndexPath(indexPath)
                return
            }
        }
    }

    // MARK: DraggableViewGestureRecognizerDelegate

    func draggableViewGestureRecognizer(gestureRecognizer: DraggableViewGestureRecognizer, shouldResetView view: UIView) -> Bool {
        return false
    }

    func draggableViewGestureRecognizer(gestureRecognizer: DraggableViewGestureRecognizer, shouldAnimateResetView view: UIView) -> Bool {
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

        init(viewController: JobsViewController) {
            super.init(target: viewController, action: "jobsTableViewCellGestureRecognized:")
            jobsViewController = viewController
        }

        override private var initialView: UIView! {
            didSet {
                if let initialView = initialView {
                    if initialView.superview!.isKindOfClass(JobTableViewCell) {
                    }
                } else if let _ = oldValue {
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
        logInfo("Deinitialized jobs view controller")
    }
}
