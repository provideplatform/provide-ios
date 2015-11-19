//
//  JobViewController.swift
//  provide
//
//  Created by Kyle Thomas on 11/17/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class JobViewController: UIViewController, BlueprintViewControllerDelegate {

    private var blueprintViewController: BlueprintViewController!

    var job: Job! {
        didSet {
            if let job = job {
                navigationItem.title = job.name
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = job.name

        blueprintViewController = UIStoryboard("Blueprint").instantiateViewControllerWithIdentifier("BlueprintViewController") as! BlueprintViewController
        blueprintViewController.blueprintViewControllerDelegate = self

        dispatch_after_delay(0.0) {
            self.blueprintViewController.view.bounds = self.view.frame
            self.view.addSubview(self.blueprintViewController.view)
        }
    }

    // MARK: BlueprintViewControllerDelegate

    func jobForBlueprintViewController(viewController: BlueprintViewController) -> Job! {
        return job
    }
}
