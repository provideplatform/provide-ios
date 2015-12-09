//
//  JobWizardTabBarController.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class JobWizardTabBarController: UITabBarController, UITabBarControllerDelegate, JobWizardViewControllerDelegate {

    var job: Job!

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        for viewController in viewControllers! {
            if viewController.isKindOfClass(JobWizardViewController) {
                (viewController as! JobWizardViewController).delegate = self
            }
        }
    }

    // MARK: UITabBarControllerDelegate

    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        // no-op
    }

    // MARK: JobWizardViewControllerDelegate

    func jobForJobWizardViewController(viewController: JobWizardViewController) -> Job! {
        return job
    }
}
