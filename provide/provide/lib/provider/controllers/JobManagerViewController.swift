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
                
//                if job.status == "in_progress" || job.status == "en_route" {
//                    timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "refreshInProgress", userInfo: nil, repeats: true)
//                }
            }
        }
    }

    private var timer: NSTimer!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Manage Job"

        if isIPad() {
            navigationItem.rightBarButtonItems = []
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
    }

    // MARK: ManifestViewControllerDelegate
    
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
        }

        if let expenseItem = expenseItem {
            navigationItem.rightBarButtonItems = [expenseItem]
        }
        return navigationItem
    }

    private var expenseItem: UIBarButtonItem! {
        if let job = job {
            let expenseItemImage = FAKFontAwesome.dollarIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0))
            let expenseBarButtonItem = NavigationBarButton.barButtonItemWithImage(expenseItemImage, target: self, action: "expense:")
            expenseBarButtonItem.enabled = ["awaiting_schedule", "scheduled", "in_progress"].indexOfObject(job.status) != nil
            return expenseBarButtonItem
        }
        return nil
    }

    func expense(sender: UIBarButtonItem!) {
        let expenseCaptureViewController = UIStoryboard("ExpenseCapture").instantiateInitialViewController() as! ExpenseCaptureViewController
        expenseCaptureViewController.modalPresentationStyle = .OverCurrentContext
        expenseCaptureViewController.expenseCaptureViewControllerDelegate = self

        presentViewController(expenseCaptureViewController, animated: true)
    }

    // MARK: ExpenseCaptureViewControllerDelegate

    func expenseCaptureViewController(viewController: ExpenseCaptureViewController, didCaptureReceipt receipt: UIImage, recognizedTexts texts: [String]!) {

    }

    func expensableForExpenseCaptureViewController(viewController: ExpenseCaptureViewController) -> Model {
        return job
    }

    func expenseCaptureViewController(viewController: ExpenseCaptureViewController, didCreateExpense expense: Expense) {

    }

    func expenseCaptureViewControllerBeganCreatingExpense(viewController: ExpenseCaptureViewController) {

    }
}
