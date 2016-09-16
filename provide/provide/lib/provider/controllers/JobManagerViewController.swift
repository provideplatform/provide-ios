//
//  JobManagerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import FontAwesomeKit
import KTSwiftExtensions

protocol JobManagerViewControllerDelegate: NSObjectProtocol {
    func jobManagerViewController(_ viewController: JobManagerViewController, numberOfSectionsInTableView tableView: UITableView) -> Int
    func jobManagerViewController(_ viewController: JobManagerViewController, tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    func jobManagerViewController(_ viewController: JobManagerViewController, tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat
    func jobManagerViewController(_ viewController: JobManagerViewController, cellForTableView tableView: UITableView, atIndexPath indexPath: IndexPath) -> UITableViewCell!
    func jobManagerViewController(_ viewController: JobManagerViewController, tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath)
    func jobManagerViewController(_ viewController: JobManagerViewController, didCreateExpense expense: Expense)
}

class JobManagerViewController: ViewController, JobManagerHeaderViewControllerDelegate, CommentsViewControllerDelegate, ManifestViewControllerDelegate, ExpensesViewControllerDelegate, ExpenseCaptureViewControllerDelegate {

    weak var delegate: JobManagerViewControllerDelegate!
    
    fileprivate var jobManagerHeaderViewController: JobManagerHeaderViewController!
    fileprivate var commentsViewController: CommentsViewController!
    fileprivate var manifestViewController: ManifestViewController!

    weak var job: Job! {
        didSet {
            reload()
        }
    }

    fileprivate var timer: Timer!

    fileprivate var dismissItem: UIBarButtonItem! {
        let dismissItem = UIBarButtonItem(title: "DISMISS", style: .plain, target: self, action: #selector(JobManagerViewController.dismiss(_:)))
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: UIControlState())
        return dismissItem
    }

    fileprivate var startItem: UIBarButtonItem! {
        let startItem = UIBarButtonItem(title: "START JOB", style: .plain, target: self, action: #selector(JobManagerViewController.start(_:)))
        startItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: UIControlState())
        return startItem
    }

    fileprivate var reviewAndCompleteItem: UIBarButtonItem! {
        let reviewAndCompleteItem = UIBarButtonItem(title: "REVIEW & COMPLETE", style: .plain, target: self, action: #selector(JobManagerViewController.reviewAndComplete(_:)))
        reviewAndCompleteItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: UIControlState())
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

    func start(_ sender: UIBarButtonItem) {
        job.updateJobWithStatus("in_progress",
            onSuccess: { statusCode, mappingResult in
                self.reload()
            },
            onError: { error, statusCode, responseString in

            }
        )
    }

    func reviewAndComplete(_ sender: UIBarButtonItem) {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .alert : .actionSheet
        let alertController = UIAlertController(title: "Are you sure you want to mark this job as ready for review?", message: nil, preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        let reviewAndCompleteAction = UIAlertAction(title: "Yes, Review & Complete Job", style: .default) { action in
            self.job.updateJobWithStatus("pending_completion",
                onSuccess: { statusCode, mappingResult in
                    self.reload()
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "JobDidTransitionToPendingCompletion"), object: self.job, userInfo: nil)
                },
                onError: { error, statusCode, responseString in

                }
            )
        }
        alertController.addAction(reviewAndCompleteAction)

        presentViewController(alertController, animated: true)
    }

    func dismiss(_ sender: UIBarButtonItem) {
        if let presentedViewController = presentedViewController {
            if presentedViewController.isKind(of: UINavigationController.self) {
                let navigationController = presentedViewController as! UINavigationController
                if navigationController.viewControllers.count > 1 {
                    navigationController.popViewController(animated: true)
                } else {
                    navigationController.presentingViewController?.dismissViewController(true)
                }
            } else {
                dismissViewController(true)

            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier! == "JobManagerHeaderViewControllerEmbedSegue" {
            jobManagerHeaderViewController = segue.destination as! JobManagerHeaderViewController
            jobManagerHeaderViewController.jobManagerHeaderViewControllerDelegate = self
        } else if segue.identifier! == "CommentsViewControllerEmbedSegue" {
            commentsViewController = (segue.destination as! UINavigationController).viewControllers.first! as! CommentsViewController
            commentsViewController.commentsViewControllerDelegate = self
        } else if segue.identifier! == "ManifestViewControllerEmbedSegue" {
            manifestViewController = (segue.destination as! UINavigationController).viewControllers.first! as! ManifestViewController
            manifestViewController.title = "MATERIALS"
            manifestViewController.delegate = self
        } else if segue.identifier! == "ManifestViewControllerShowSegue" {
            manifestViewController = (segue.destination as! UINavigationController).viewControllers.first! as! ManifestViewController
            manifestViewController.title = "MATERIALS"
            manifestViewController.delegate = self
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        dispatch_after_delay(0.0) {
            self.manifestViewController.reloadTableView()
        }
    }

    // MARK: ManifestViewControllerDelegate

    func itemsForManifestViewController(_ viewController: UIViewController, forSegmentIndex segmentIndex: Int) -> [Product]! {
        if segmentIndex == 0 {
            return job?.materials?.map({ $0.product })
        }
        return [Product]()
    }
    
    func workOrderForManifestViewController(_ viewController: UIViewController) -> WorkOrder! {
        return nil //workOrder
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: JobManagerHeaderViewControllerDelegate

    func jobManagerHeaderViewController(_ viewController: JobManagerHeaderViewController, delegateForExpensesViewController expensesViewController: ExpensesViewController) -> ExpensesViewControllerDelegate! {
        return self
    }

    // MARK: CommentsViewControllerDelegate

    func queryParamsForCommentsViewController(_ viewController: CommentsViewController) -> [String : AnyObject]! {
        return [String : AnyObject]()
    }

    func commentableTypeForCommentsViewController(_ viewController: CommentsViewController) -> String {
        return "job"
    }

    func commentableIdForCommentsViewController(_ viewController: CommentsViewController) -> Int {
        return job.id
    }

    func commentsViewController(_ viewController: CommentsViewController, shouldCreateComment comment: String, withImageAttachment image: UIImage! = nil) {
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

    fileprivate func reload() {
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

    fileprivate func reloadJobComments() {
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

    fileprivate func reloadJobManifest() {
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

    func segmentsForManifestViewController(_ viewController: UIViewController) -> [String]! {
        return ["MATERIALS"]
    }

    func manifestViewController(_ viewController: UIViewController, tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCell(withIdentifier: "jobProductTableViewCell") as! JobProductTableViewCell
        cell.enableEdgeToEdgeDividers()
        cell.jobProduct = job.materials[(indexPath as NSIndexPath).row]
        return cell
    }

    func manifestViewController(_ viewController: UIViewController, tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        print("selected job product \(job.materials[(indexPath as NSIndexPath).row])")
    }

    func navigationControllerNavigationItemForViewController(_ viewController: UIViewController) -> UINavigationItem! {
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

    fileprivate var expenseItem: UIBarButtonItem! {
        if let job = job {
            let expenseItemImage = FAKFontAwesome.dollarIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0))
            let expenseBarButtonItem = NavigationBarButton.barButtonItemWithImage(expenseItemImage!, target: self, action: "expense:")
            expenseBarButtonItem.isEnabled = ["configuring", "in_progress"].index(of: job.status) != nil
            return expenseBarButtonItem
        }
        return nil
    }

    func expense(_ sender: UIBarButtonItem!) {
        if let navigationController = presentedViewController as? UINavigationController {
            let expenseCaptureViewController = UIStoryboard("ExpenseCapture").instantiateInitialViewController() as! ExpenseCaptureViewController
            expenseCaptureViewController.modalPresentationStyle = .overCurrentContext
            expenseCaptureViewController.expenseCaptureViewControllerDelegate = self

            navigationController.presentViewController(expenseCaptureViewController, animated: true)
        }
    }

    // MARK: ExpenseCaptureViewControllerDelegate

    func expenseCaptureViewController(_ viewController: ExpenseCaptureViewController, didCaptureReceipt receipt: UIImage, recognizedTexts texts: [String]!) {

    }

    func expensableForExpenseCaptureViewController(_ viewController: ExpenseCaptureViewController) -> Model {
        return job
    }

    func expenseCaptureViewController(_ viewController: ExpenseCaptureViewController, didCreateExpense expense: Expense) {
        if let jobManagerHeaderViewController = jobManagerHeaderViewController {
            jobManagerHeaderViewController.reloadJobFinancials()
        }
    }

    func expenseCaptureViewControllerBeganCreatingExpense(_ viewController: ExpenseCaptureViewController) {
        dismissViewController(true)
    }
}
