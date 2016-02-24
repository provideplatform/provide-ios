//
//  JobManagerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol JobManagerViewControllerDelegate: NSObjectProtocol {
    func jobManagerViewController(viewController: JobManagerViewController, numberOfSectionsInTableView tableView: UITableView) -> Int
    func jobManagerViewController(viewController: JobManagerViewController, tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    func jobManagerViewController(viewController: JobManagerViewController, tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    func jobManagerViewController(viewController: JobManagerViewController, cellForTableView tableView: UITableView, atIndexPath indexPath: NSIndexPath) -> UITableViewCell!
    func jobManagerViewController(viewController: JobManagerViewController, tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    func jobManagerViewController(viewController: JobManagerViewController, didCreateExpense expense: Expense)
}

class JobManagerViewController: ViewController, JobManagerHeaderViewControllerDelegate, CommentsViewControllerDelegate, ManifestViewControllerDelegate, ExpensesViewControllerDelegate, ExpenseCaptureViewControllerDelegate {

    weak var delegate: JobManagerViewControllerDelegate!
    
    private var jobManagerHeaderViewController: JobManagerHeaderViewController!
    private var commentsViewController: CommentsViewController!
    private var manifestViewController: ManifestViewController!

    weak var job: Job! {
        didSet {
            reload()
        }
    }

    private var timer: NSTimer!

    private var dismissItem: UIBarButtonItem! {
        let dismissItem = UIBarButtonItem(title: "DISMISS", style: .Plain, target: self, action: "dismiss:")
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return dismissItem
    }

    private var startItem: UIBarButtonItem! {
        let startItem = UIBarButtonItem(title: "START JOB", style: .Plain, target: self, action: "start:")
        startItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return startItem
    }

    private var reviewAndCompleteItem: UIBarButtonItem! {
        let reviewAndCompleteItem = UIBarButtonItem(title: "REVIEW & COMPLETE", style: .Plain, target: self, action: "reviewAndComplete:")
        reviewAndCompleteItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return reviewAndCompleteItem
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        //tabBarItem.image = FAKFontAwesome.briefcaseIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "MANAGE JOB"

        if isIPad() {
            navigationItem.rightBarButtonItems = []
        }
    }

    func start(sender: UIBarButtonItem) {
        job.updateJobWithStatus("in_progress",
            onSuccess: { statusCode, mappingResult in
                self.reload()
            },
            onError: { error, statusCode, responseString in

            }
        )
    }

    func reviewAndComplete(sender: UIBarButtonItem) {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .Alert : .ActionSheet
        let alertController = UIAlertController(title: "Are you sure you want to mark this job as ready for review?", message: nil, preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)

        let reviewAndCompleteAction = UIAlertAction(title: "Yes, Review & Complete Job", style: .Default) { action in
            self.job.updateJobWithStatus("pending_completion",
                onSuccess: { statusCode, mappingResult in
                    self.reload()
                    NSNotificationCenter.defaultCenter().postNotificationName("JobDidTransitionToPendingCompletion", object: self.job, userInfo: nil)
                },
                onError: { error, statusCode, responseString in

                }
            )
        }
        alertController.addAction(reviewAndCompleteAction)

        presentViewController(alertController, animated: true)
    }

    func dismiss(sender: UIBarButtonItem) {
        if let presentedViewController = presentedViewController {
            if presentedViewController.isKindOfClass(UINavigationController) {
                let navigationController = presentedViewController as! UINavigationController
                if navigationController.viewControllers.count > 1 {
                    navigationController.popViewControllerAnimated(true)
                } else {
                    navigationController.presentingViewController?.dismissViewController(animated: true)
                }
            } else {
                dismissViewController(animated: true)

            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier! == "JobManagerHeaderViewControllerEmbedSegue" {
            jobManagerHeaderViewController = segue.destinationViewController as! JobManagerHeaderViewController
            jobManagerHeaderViewController.jobManagerHeaderViewControllerDelegate = self
        } else if segue.identifier! == "CommentsViewControllerEmbedSegue" {
            commentsViewController = (segue.destinationViewController as! UINavigationController).viewControllers.first! as! CommentsViewController
            commentsViewController.commentsViewControllerDelegate = self
        } else if segue.identifier! == "ManifestViewControllerEmbedSegue" {
            manifestViewController = (segue.destinationViewController as! UINavigationController).viewControllers.first! as! ManifestViewController
            manifestViewController.title = "MATERIALS"
            manifestViewController.delegate = self
        } else if segue.identifier! == "ManifestViewControllerShowSegue" {
            manifestViewController = (segue.destinationViewController as! UINavigationController).viewControllers.first! as! ManifestViewController
            manifestViewController.title = "MATERIALS"
            manifestViewController.delegate = self
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        dispatch_after_delay(0.0) {
            self.manifestViewController.reloadTableView()
        }
    }

    // MARK: ManifestViewControllerDelegate

    func itemsForManifestViewController(viewController: UIViewController, forSegmentIndex segmentIndex: Int) -> [Product]! {
        if segmentIndex == 0 {
            return job?.materials?.map({ $0.product })
        }
        return [Product]()
    }
    
    func workOrderForManifestViewController(viewController: UIViewController) -> WorkOrder! {
        return nil //workOrder
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: JobManagerHeaderViewControllerDelegate

    func jobManagerHeaderViewController(viewController: JobManagerHeaderViewController, delegateForExpensesViewController expensesViewController: ExpensesViewController) -> ExpensesViewControllerDelegate! {
        return self
    }

    // MARK: CommentsViewControllerDelegate

    func commentsForCommentsViewController(viewController: CommentsViewController) -> [Comment] {
        if let job = job {
            if let comments = job.comments {
                return comments
            } else {
                reloadJobComments()
            }
        }
        return [Comment]()
    }

    func commentsViewController(viewController: CommentsViewController, shouldCreateComment comment: String) {
        if let job = job {
            job.addComment(comment,
                onSuccess: { statusCode, mappingResult in
                    viewController.reloadCollectionView()
                },
                onError: { error, statusCode, responseString in

                }
            )
        }
    }

    private func reload() {
        if let job = job {
            if let jobManagerHeaderViewController = jobManagerHeaderViewController {
                jobManagerHeaderViewController.job = job
            }

            if let manifestViewController = manifestViewController {
                if let materials = job.materials {
                    manifestViewController.products = materials.map({ $0.product })
                } else {
                    reloadJobManifest()
                }
            }

            navigationItem.prompt = job.status

            if job.canTransitionToInProgressStatus {
                navigationItem.rightBarButtonItems = [startItem]
            } else if job.canTransitionToReviewAndCompleteStatus {
                navigationItem.rightBarButtonItems = [reviewAndCompleteItem]
            } else {
                navigationItem.rightBarButtonItems = []
            }

            //                if job.status == "in_progress" || job.status == "en_route" {
            //                    timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "refreshInProgress", userInfo: nil, repeats: true)
            //                }
        }
    }

    private func reloadJobComments() {
        if let job = job {
            job.reloadComments(
                { statusCode, mappingResult in
                    self.commentsViewController.reloadCollectionView()
                },
                onError: { error, statusCode, responseString in

                }
            )
        }
    }

    private func reloadJobManifest() {
        if let job = job {
            job.reloadMaterials(
                { statusCode, mappingResult in
                    self.manifestViewController.products = job.materials.map({ $0.product })
                    self.manifestViewController.reload()
                },
                onError: { error, statusCode, responseString in

                }
            )
        }
    }

    // MARK: ManifestViewControllerDelegate

    func segmentsForManifestViewController(viewController: UIViewController) -> [String]! {
        return ["MATERIALS"]
    }

    func manifestViewController(viewController: UIViewController, tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier("jobProductTableViewCell") as! JobProductTableViewCell
        cell.enableEdgeToEdgeDividers()
        cell.jobProduct = job.materials[indexPath.row]
        return cell
    }

    func manifestViewController(viewController: UIViewController, tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("selected job product \(job.materials[indexPath.row])")
    }

    func navigationControllerNavigationItemForViewController(viewController: UIViewController) -> UINavigationItem! {
        let navigationItem = UINavigationItem()
        if viewController is ManifestViewController {
            navigationItem.title = segmentsForManifestViewController(viewController as! ManifestViewController)[0]
        } else if viewController is ExpensesViewController {
            navigationItem.title = "EXPENSES"

            if let expenseItem = expenseItem {
                navigationItem.rightBarButtonItems = [expenseItem]
            }
        }

        if !isIPad() {
            navigationItem.leftBarButtonItems = [dismissItem]
        }

        return navigationItem
    }

    private var expenseItem: UIBarButtonItem! {
        if let job = job {
            let expenseItemImage = FAKFontAwesome.dollarIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0))
            let expenseBarButtonItem = NavigationBarButton.barButtonItemWithImage(expenseItemImage, target: self, action: "expense:")
            expenseBarButtonItem.enabled = ["configuring", "in_progress"].indexOfObject(job.status) != nil
            return expenseBarButtonItem
        }
        return nil
    }

    func expense(sender: UIBarButtonItem!) {
        if let navigationController = presentedViewController as? UINavigationController {
            let expenseCaptureViewController = UIStoryboard("ExpenseCapture").instantiateInitialViewController() as! ExpenseCaptureViewController
            expenseCaptureViewController.modalPresentationStyle = .OverCurrentContext
            expenseCaptureViewController.expenseCaptureViewControllerDelegate = self

            navigationController.presentViewController(expenseCaptureViewController, animated: true)
        }
    }

    // MARK: ExpenseCaptureViewControllerDelegate

    func expenseCaptureViewController(viewController: ExpenseCaptureViewController, didCaptureReceipt receipt: UIImage, recognizedTexts texts: [String]!) {

    }

    func expensableForExpenseCaptureViewController(viewController: ExpenseCaptureViewController) -> Model {
        return job
    }

    func expenseCaptureViewController(viewController: ExpenseCaptureViewController, didCreateExpense expense: Expense) {
        if let jobManagerHeaderViewController = jobManagerHeaderViewController {
            jobManagerHeaderViewController.reloadJobFinancials()
        }
    }

    func expenseCaptureViewControllerBeganCreatingExpense(viewController: ExpenseCaptureViewController) {
        dismissViewController(animated: true)
    }
}
