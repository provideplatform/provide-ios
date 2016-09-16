//
//  JobsViewController.swift
//  provide
//
//  Created by Kyle Thomas on 11/17/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

class JobsViewController: ViewController,
                          UITableViewDelegate,
                          UITableViewDataSource,
                          UIPopoverPresentationControllerDelegate,
                          JobCreationViewControllerDelegate,
                          JobTableViewCellDelegate,
                          KTDraggableViewGestureRecognizerDelegate {

    @IBOutlet fileprivate weak var addJobBarButtonItem: UIBarButtonItem! {
        didSet {
            if let addJobBarButtonItem = addJobBarButtonItem {
                addJobBarButtonItem.tintColor = Color.applicationDefaultBarButtonItemTintColor()
            }
        }
    }
    @IBOutlet fileprivate var tableView: UITableView!

    fileprivate var page = 1
    fileprivate let rpp = 10
    fileprivate var lastJobIndex = -1

    fileprivate var refreshControl: UIRefreshControl!

    fileprivate weak var jobCreationViewController: JobCreationViewController!

    fileprivate var cancellingJob = false

    fileprivate var jobs = [Job]() {
        didSet {
            tableView?.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "JOBS"

        setupPullToRefresh()

        NotificationCenter.default.addObserverForName("FloorplanChanged") { notification in
            if let floorplan = notification.object as? Floorplan {
                var i = 0
                for job in self.jobs {
                    if job.id == floorplan.jobId {
                        if job.thumbnailImageUrl == nil {
                            let indexPath = i
                            job.reload([:],
                                onSuccess: { statusCode, mappingResult in
                                    if let tableView = self.tableView {
                                        tableView.reloadRows(at: [NSIndexPath(row: indexPath, section: 0) as IndexPath], with: .none)
                                    }
                                },
                                onError: { error, statusCode, responseString in

                                }
                            )
                        }
                    }

                    i += 1
                }
            }
        }

        NotificationCenter.default.addObserverForName("JobChanged") { notification in
            if let job = notification.object as? Job {
                var i = 0
                for j in self.jobs {
                    if job.id == j.id {
                        let indexPath = i
                        j.reload([:],
                            onSuccess: { statusCode, mappingResult in
                                if self.jobs.count > 0 {
                                    if let tableView = self.tableView {
                                        tableView.reloadRows(at: [NSIndexPath(row: indexPath, section: 0) as IndexPath], with: .none)
                                    }
                                }
                            },
                            onError: { error, statusCode, responseString in

                            }
                        )
                    }

                    i += 1
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "JobViewControllerSegue" {
            if let sender = sender {
                (segue.destination as! JobViewController).job = (sender as! JobTableViewCell).job
            }
        } else if segue.identifier == "JobFloorplansViewControllerSegue" {
            if let sender = sender {
                var job: Job!
                if sender is JobTableViewCell {
                    job = (sender as! JobTableViewCell).job
                } else if sender is Job {
                    job = sender as! Job
                }

                if let job = job {
                    let cacheAge = job.timeIntervalSinceLastRefreshDate()
                    if cacheAge >= 0.0 {
                        if cacheAge > 60.0 {
                            job.reload(["include_supervisors": "true" as AnyObject],
                                onSuccess: { statusCode, mappingResult in
                                    if let job = mappingResult?.firstObject as? Job {
                                        var index: Int?
                                        for j in self.jobs {
                                            if j.id == job.id {
                                                index = self.jobs.indexOfObject(j)
                                            }
                                        }

                                        if let index = index {
                                            self.jobs.replaceSubrange(index...index, with: [job])
                                        }

                                        (segue.destination as! JobFloorplansViewController).job = job
                                    }
                                },
                                onError: { error, statusCode, responseString in

                                }
                            )
                        } else {
                            (segue.destination as! JobFloorplansViewController).job = job
                        }
                    }
                }
            }
        } else if segue.identifier == "JobWizardTabBarControllerSegue" {
            if let sender = sender {
                var job: Job!
                if sender is JobTableViewCell {
                    job = (sender as! JobTableViewCell).job
                } else if sender is Job {
                    job = sender as! Job
                }

                if let job = job {
                    let cacheAge = job.timeIntervalSinceLastRefreshDate()
                    if cacheAge >= 0.0 {
                        if cacheAge > 60.0 {
                            job.reload(["include_supervisors": "true" as AnyObject],
                                onSuccess: { statusCode, mappingResult in
                                    if let job = mappingResult?.firstObject as? Job {
                                        var index: Int?
                                        for j in self.jobs {
                                            if j.id == job.id {
                                                index = self.jobs.indexOfObject(j)
                                            }
                                        }

                                        if let index = index {
                                            self.jobs.replaceSubrange(index...index, with: [job])
                                        }

                                        (segue.destination as! JobWizardTabBarController).job = job
                                    }
                                },
                                onError: { error, statusCode, responseString in

                                }
                            )
                        } else {
                            (segue.destination as! JobWizardTabBarController).job = job
                        }
                    }
                }
            }
        } else if segue.identifier == "JobCreationViewControllerPopoverSegue" {
            let navigationController = segue.destination as! UINavigationController
            navigationController.preferredContentSize = CGSize(width: view.frame.width * 0.6, height: 650)
            navigationController.popoverPresentationController!.delegate = self

            jobCreationViewController = navigationController.viewControllers.first! as! JobCreationViewController
            jobCreationViewController.delegate = self
        }
    }

    fileprivate func setupPullToRefresh() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(JobsViewController.reset), for: .valueChanged)

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

        JobService.sharedService().fetch(page,
                                         rpp: rpp,
                                         companyId: ApiService.sharedService().defaultCompanyId,
                                         status: "configuring,in_progress,pending_completion",
                                         includeCustomer: true,
                                         includeExpenses: false,
                                         includeProducts: false) { jobs in
            self.jobs += jobs
            self.tableView.reloadData()
            self.refreshControl.endRefreshing()
        }
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return jobs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "jobsTableViewCellReuseIdentifier", for: indexPath) as! JobTableViewCell
        cell.jobTableViewCellDelegate = self
        cell.job = jobs[(indexPath as NSIndexPath).row]
        return cell
    }

    func cancelJobAtIndexPath(_ indexPath: IndexPath) {
        let job = jobs[(indexPath as NSIndexPath).row]
        if let cell = tableView.cellForRow(at: indexPath) as? JobTableViewCell {
            if ["canceled", "completed"].index(of: job.status) == nil {
                cell.dismiss()
                promptForJobCancellation(job, cell: cell)
            }
        }
    }

    func promptForJobCancellation(_ job: Job, cell: JobTableViewCell) {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .alert : .actionSheet
        let alertController = UIAlertController(title: "Are you sure you want to cancel this job?", message: nil, preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "No, Don't Cancel", style: .cancel) { action in
            cell.reset()
        }
        alertController.addAction(cancelAction)

        let setCancelJobAction = UIAlertAction(title: "Cancel Job", style: .destructive) { action in
            DispatchQueue.global(qos: DispatchQoS.default.qosClass).async {
                job.cancel(
                    { statusCode, mappingResult in
                        if let indexPath = self.tableView.indexPath(for: cell) {
                            self.tableView?.beginUpdates()
                            self.jobs.removeObject(job)
                            self.tableView?.deleteRows(at: [indexPath], with: .top)
                            self.tableView?.endUpdates()
                        }
                    },
                    onError: { error, statusCode, responseString in
                        
                    }
                )
            }
        }
        alertController.addAction(setCancelJobAction)

        presentViewController(alertController, animated: true)
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let jobIndex = (indexPath as NSIndexPath).row
        if jobIndex == jobs.count - 1 && jobIndex > lastJobIndex {
            page += 1
            lastJobIndex = jobIndex
            refresh()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        performSegue(withIdentifier: "JobFloorplansViewControllerSegue", sender: cell)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: JobCreationViewControllerDelegate

    func jobCreationViewController(_ viewController: JobCreationViewController, didCreateJob job: Job) {
        jobs.insert(job, at: 0)

        if let jobCreationViewController = jobCreationViewController {
            jobCreationViewController.presentingViewController?.dismissViewController(true)
        }

        performSegue(withIdentifier: "JobFloorplansViewControllerSegue", sender: job)
    }

    // MARK: JobTableViewCellDelegate

    func jobTableViewCell(_ tableViewCell: JobTableViewCell, shouldCancelJob job: Job) {
        for j in jobs {
            if j.id == job.id {
                let indexPath = IndexPath(row: jobs.indexOfObject(j)!, section: 0)
                cancelJobAtIndexPath(indexPath)
                return
            }
        }
    }

    // MARK: KTDraggableViewGestureRecognizerDelegate

    func draggableViewGestureRecognizer(_ gestureRecognizer: KTDraggableViewGestureRecognizer, shouldResetView view: UIView) -> Bool {
        return false
    }

    func draggableViewGestureRecognizer(_ gestureRecognizer: KTDraggableViewGestureRecognizer, shouldAnimateResetView view: UIView) -> Bool {
        return false
    }

    func jobsTableViewCellGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        // no-op
    }

    fileprivate class JobTableViewCellGestureRecognizer: KTDraggableViewGestureRecognizer {

        fileprivate weak var tableView: UITableView! {
            return jobsViewController?.tableView
        }

        fileprivate weak var jobsViewController: JobsViewController!

        fileprivate var initialBackgroundColor: UIColor!

        fileprivate var shouldCancelJob = false

        init(viewController: JobsViewController) {
            super.init(target: viewController, action: #selector(JobsViewController.jobsTableViewCellGestureRecognized(_:)))
            jobsViewController = viewController
        }

        override open var initialView: UIView! {
            didSet {
                if let initialView = self.initialView {
                    if initialView.superview!.isKind(of: JobTableViewCell.self) {
                    }
                } else if let _ = oldValue {
                    shouldCancelJob = false
                }
            }
        }

        fileprivate func dismissCell() {
            if let tableViewCell = initialView.superview?.superview as? JobTableViewCell {
                tableViewCell.dismiss()
            }
        }

        fileprivate func restoreCell() {
            if let tableViewCell = initialView.superview?.superview as? JobTableViewCell {
                tableViewCell.reset()
            }
        }

        fileprivate override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
            let cell = initialView.superview!.superview! as! JobTableViewCell
            let indexPath = tableView.indexPath(for: cell)!
            let selected = abs(initialView.frame.origin.x) <= 5.0

            if shouldCancelJob {
                jobsViewController?.cancelJobAtIndexPath(indexPath)
            } else {
                restoreCell()
            }

            super.touchesEnded(touches, with: event)

            if selected {
                dispatch_after_delay(0.0) { [weak self] in
                    self!.tableView?.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                    self!.jobsViewController?.performSegue(withIdentifier: "JobFloorplansViewControllerSegue", sender: cell)
                    cell.setHighlighted(false, animated: true)
                    cell.setSelected(false, animated: true)
                }
            }
        }

        fileprivate override func drag(_ xOffset: CGFloat, yOffset: CGFloat) {
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
                initialView.backgroundColor = Color.abandonedStatusColor().withAlphaComponent(cancelStrength / 0.75)
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

        NotificationCenter.default.removeObserver(self)
    }
}
