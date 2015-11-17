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

    private var dismissItem: UIBarButtonItem! {
        let dismissItem = UIBarButtonItem(title: "DISMISS", style: .Plain, target: self, action: "dismiss:")
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return dismissItem
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        blueprintViewController = UIStoryboard("Blueprint").instantiateViewControllerWithIdentifier("BlueprintViewController") as! BlueprintViewController
        blueprintViewController.blueprintViewControllerDelegate = self

        dispatch_after_delay(0.0) {
            self.blueprintViewController.view.bounds = self.view.frame
            self.view.addSubview(self.blueprintViewController.view)
        }

        refreshNavigationItem()
    }

    private func refreshNavigationItem() {
        navigationItem.title = job.name
        navigationItem.leftBarButtonItems = [dismissItem]

        if let navigationController = navigationController {
            navigationController.setNavigationBarHidden(false, animated: true)
        }
    }

    func dismiss(sender: UIBarButtonItem!) {
        clearNavigationItem()

        if let navigationController = navigationController {
            navigationController.popViewControllerAnimated(true)
        }
    }

    private func clearNavigationItem() {
        navigationItem.hidesBackButton = true
        navigationItem.prompt = nil
        navigationItem.leftBarButtonItems = []
        navigationItem.rightBarButtonItems = []
    }

    // MARK: BlueprintViewControllerDelegate

    func jobForBlueprintViewController(viewController: BlueprintViewController) -> Job! {
        return job
    }
}
