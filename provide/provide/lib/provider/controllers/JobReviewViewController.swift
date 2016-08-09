//
//  JobReviewViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

class JobReviewViewController: ViewController {

    weak var job: Job! {
        didSet {
            reload()
        }
    }

    private var completeItem: UIBarButtonItem! {
        let completeItem = UIBarButtonItem(title: "COMPLETE JOB", style: .Plain, target: self, action: #selector(JobReviewViewController.complete(_:)))
        completeItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return completeItem
    }

    private func reload() {
        if job.status == "pending_completion" {
            navigationItem.rightBarButtonItems = [completeItem]
        } else {
            navigationItem.rightBarButtonItems = []
        }
    }

    func complete(sender: UIBarButtonItem) {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .Alert : .ActionSheet
        let alertController = UIAlertController(title: "Are you sure you want to complete this job?", message: nil, preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)

        let reviewAndCompleteAction = UIAlertAction(title: "Yes, Complete Job", style: .Default) { action in
            self.job.updateJobWithStatus("completed",
                onSuccess: { statusCode, mappingResult in
                    self.reload()
                },
                onError: { error, statusCode, responseString in

                }
            )
        }
        alertController.addAction(reviewAndCompleteAction)

        presentViewController(alertController, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "REVIEW & COMPLETE"
    }
}
