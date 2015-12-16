//
//  JobManagerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol JobManagerViewControllerDelegate {
    func jobManagerViewController(viewController: JobManagerViewController, numberOfSectionsInTableView tableView: UITableView) -> Int
    func jobManagerViewController(viewController: JobManagerViewController, tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    func jobManagerViewController(viewController: JobManagerViewController, tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    func jobManagerViewController(viewController: JobManagerViewController, cellForTableView tableView: UITableView, atIndexPath indexPath: NSIndexPath) -> UITableViewCell!
    func jobManagerViewController(viewController: JobManagerViewController, tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    func jobManagerViewController(viewController: JobManagerViewController, didCreateExpense expense: Expense)
}

class JobManagerViewController: ViewController, CommentsViewControllerDelegate {

    var delegate: JobManagerViewControllerDelegate!

    private var jobManagerHeaderViewController: JobManagerHeaderViewController!
    private var commentsViewController: CommentsViewController!

    weak var job: Job! {
        didSet {
            if let job = job {
                if let jobManagerHeaderViewController = jobManagerHeaderViewController {
                    jobManagerHeaderViewController.job = job
                }

                //            job.reloadAttachments(
                //                { statusCode, mappingResult in
                //                    self.mediaCollectionView?.reloadData()
                //                },
                //                onError: { error, statusCode, responseString in
                //
                //                }
                //            )
                //
                //            job.reloadExpenses(
                //                { statusCode, mappingResult in
                //                    self.reloadTableView()
                //                },
                //                onError: { error, statusCode, responseString in
                //
                //                }
                //            )
                //
                //            job.reloadInventory(
                //                { statusCode, mappingResult in
                //                    self.reloadTableView()
                //                },
                //                onError: { error, statusCode, responseString in
                //
                //                }
                //            )
                
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
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier! == "JobManagerHeaderViewControllerEmbedSegue" {
            jobManagerHeaderViewController = segue.destinationViewController as! JobManagerHeaderViewController
        } else if segue.identifier! == "CommentsViewControllerEmbedSegue" {
            commentsViewController = (segue.destinationViewController as! UINavigationController).viewControllers.first! as! CommentsViewController
            commentsViewController.commentsViewControllerDelegate = self
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
}
