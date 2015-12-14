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

class JobManagerViewController: ViewController {

    var delegate: JobManagerViewControllerDelegate!

    weak var job: Job! {
        didSet {
            if let job = job {
                navigationItem.title = title == nil ? job.name : title

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
}
