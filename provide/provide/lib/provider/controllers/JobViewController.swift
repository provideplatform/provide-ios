//
//  JobViewController.swift
//  provide
//
//  Created by Kyle Thomas on 11/17/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class JobViewController: ViewController, BlueprintViewControllerDelegate {

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
        blueprintViewController.navigationItem.title = job.name

        navigationController!.popViewControllerAnimated(false)
        navigationController!.pushViewController(blueprintViewController, animated: false)
    }

    // MARK: BlueprintViewControllerDelegate

    func blueprintForBlueprintViewController(viewController: BlueprintViewController) -> Attachment! {
        return job.blueprint
    }

    func jobForBlueprintViewController(viewController: BlueprintViewController) -> Job! {
        return job
    }

    func blueprintImageForBlueprintViewController(viewController: BlueprintViewController) -> UIImage! {
        return nil
    }

    func modeForBlueprintViewController(viewController: BlueprintViewController) -> BlueprintViewController.Mode! {
        return .Setup
    }

    func estimateForBlueprintViewController(viewController: BlueprintViewController) -> Estimate! {
        return nil
    }

    func scaleCanBeSetByBlueprintViewController(viewController: BlueprintViewController) -> Bool {
        return false
    }

    func scaleWasSetForBlueprintViewController(viewController: BlueprintViewController) {

    }

    func newWorkOrderCanBeCreatedByBlueprintViewController(viewController: BlueprintViewController) -> Bool {
        return false
    }

    func areaSelectorIsAvailableForBlueprintViewController(viewController: BlueprintViewController) -> Bool {
        return false
    }
    
    func navigationControllerForBlueprintViewController(viewController: BlueprintViewController) -> UINavigationController! {
        return navigationController
    }

    func blueprintViewControllerCanDropWorkOrderPin(viewController: BlueprintViewController) -> Bool {
        return false
    }
}
