//
//  JobWizardTabBarController.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class JobWizardTabBarController: UITabBarController,
                                 UITabBarControllerDelegate,
                                 JobWizardViewControllerDelegate {

    weak var job: Job! {
        didSet {
            if let job = job {
                navigationItem.title = job.name

                if job.status == "completed" || job.status == "canceled" {
                    viewControllers?.removeAtIndex(4)

                    let reviewNavigationController = UIStoryboard("JobWizard").instantiateViewControllerWithIdentifier("JobReviewNavigationController")
                    viewControllers?.append(reviewNavigationController)
                }

                if let jobBlueprintsViewControllerIndex = tabBar.items!.indexOf(setupBlueprintsTabBarItem) {
                    if let jobBlueprintsViewController = (viewControllers![jobBlueprintsViewControllerIndex] as! UINavigationController).viewControllers.first! as? JobBlueprintsViewController {
                        jobBlueprintsViewController.refresh()
                    }
                }
            }
        }
    }

    private var setupBlueprintsTabBarItem: UITabBarItem! {
        if let items = tabBar.items {
            return items[0]
        }
        return nil
    }

    private var setupTeamTabBarItem: UITabBarItem! {
        if let items = tabBar.items {
            return items[1]
        }
        return nil
    }

    private var setupInventoryTabBarItem: UITabBarItem! {
        if let items = tabBar.items {
            return items[2]
        }
        return nil
    }

    private var setupWorkOrdersTabBarItem: UITabBarItem! {
        if let items = tabBar.items {
            return items[3]
        }
        return nil
    }

    private var manageJobTabBarItem: UITabBarItem! {
        if let items = tabBar.items {
            return items[4]
        }
        return nil
    }

    private var reviewTabBarItem: UITabBarItem! {
        if let items = tabBar.items {
            return items[4]
        }
        return nil
    }

    private var isEditMode: Bool {
        if let _ = job {
            let hasBlueprint = job.blueprints?.count > 0
            let hasScale = hasBlueprint && job.blueprints?.first!.metadata["scale"] != nil
            let hasSupervisor = job.supervisors?.count > 0
            let hasInventory = job.materials?.count > 0
            let hasWorkOrders = job.workOrdersCount > 0
            return !job.isWizardMode && ((hasBlueprint && hasScale && hasSupervisor && hasInventory && hasWorkOrders) || job.status != "configuring")
        }
        return false
    }

    private var shouldRenderBlueprintSetup: Bool {
        if let job = job {
            let hasBlueprint = job.blueprints?.count > 0
            let hasScale = hasBlueprint && job.blueprints?.first!.metadata["scale"] != nil
            return !isEditMode && !hasBlueprint || !hasScale
        }
        return false
    }

    private var shouldRenderTeamSetup: Bool {
        if let job = job {
            if let supervisors = job.supervisors {
                return !isEditMode && supervisors.count == 0
            }
        }
        return false
    }

    private var shouldRenderInventorySetup: Bool {
        if let job = job {
            if let materials = job.materials {
                return !isEditMode && materials.count == 0
            }
        }
        return false
    }

    private var shouldRenderWorkOrderSetup: Bool {
        if let job = job {
            return !isEditMode && job.workOrdersCount == 0
        }
        return false
    }

    private var shouldRenderManageJob: Bool {
        return isEditMode
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        dispatch_after_delay(0.0) { [weak self] in
            for viewController in self!.viewControllers! {
                if viewController.isKindOfClass(JobWizardViewController) {
                    (viewController as! JobWizardViewController).jobWizardViewControllerDelegate = self!
                }
            }

            self!.selectInitialTabBarItem()
        }

        setupTabBarAppearence()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }

    func dismiss(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }

    private func setupTabBarAppearence() {
        //tabBar.frame.size.height = 60.0

        var cropRect = tabBar.frame
        cropRect.origin.y = cropRect.size.height - tabBar.frame.height
        tabBar.backgroundImage = UIImage("bar-background")!.crop(cropRect)

        let mapPin = UIImage("map-pin")!
        tabBar.selectionIndicatorImage = mapPin.scaledToWidth(mapPin.size.width / 2.8)

        refreshSelectionIndicatorImageViewFrame()
    }

    private func refreshSelectionIndicatorImageViewFrame() {
        if let selectionIndicatorImage = tabBar.selectionIndicatorImage {
            for view in tabBar.subviews {
                for v in view.subviews {
                    if v.isKindOfClass(UIImageView) {
                        if (v as! UIImageView).image == selectionIndicatorImage {
                            //v.frame = CGRectInset(v.frame, 0.0, -12.0)
                            view.sendSubviewToBack(v)
                        }
                    }
                }
            }
        }
    }

    private func selectInitialTabBarItem() {
        var item: UITabBarItem?

        if shouldRenderManageJob {
            item = manageJobTabBarItem
        } else if shouldRenderBlueprintSetup {
            item = setupBlueprintsTabBarItem
        } else if shouldRenderTeamSetup {
            item = setupTeamTabBarItem
        } else if shouldRenderInventorySetup {
            item = setupInventoryTabBarItem
        } else if shouldRenderWorkOrderSetup {
            item = setupWorkOrdersTabBarItem
        }

        if let item = item {
            selectedIndex = tabBar.items!.indexOf(item)!
        }
    }

    // MARK: UITabBarControllerDelegate

    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        if let job = job {
            if viewController.isKindOfClass(UINavigationController) {
                if (viewController as! UINavigationController).viewControllers.count == 1 {
                    let rootViewController = (viewController as! UINavigationController).viewControllers.first!
                    if rootViewController.isKindOfClass(JobReviewViewController) {
                        return ["canceled", "completed"].indexOf(job.status) > -1
                    }
                }
            }
        }
        return true
    }

    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        refreshSelectionIndicatorImageViewFrame()
    }

    // MARK: JobWizardViewControllerDelegate

    func jobForJobWizardViewController(viewController: JobWizardViewController) -> Job! {
        return job
    }

    func blueprintImageForJobWizardViewController(viewController: JobWizardViewController) -> UIImage! {
        if viewController.isKindOfClass(UINavigationController) {
            let rootViewController = (viewController as UINavigationController).viewControllers.first!
            if let _ = rootViewController as? BlueprintViewController {
                if let jobBlueprintsViewControllerIndex = tabBar.items!.indexOf(setupBlueprintsTabBarItem) {
                    if let jobBlueprintsViewController = (viewControllers![jobBlueprintsViewControllerIndex] as! UINavigationController).viewControllers.first! as? JobBlueprintsViewController {
                        return jobBlueprintsViewController.teardownBlueprintViewController()
                    }
                }
            } else if let _ = rootViewController as? JobBlueprintsViewController {
                if let blueprintViewControllerIndex = tabBar.items!.indexOf(setupWorkOrdersTabBarItem) {
                    if let blueprintViewController = (viewControllers![blueprintViewControllerIndex] as! UINavigationController).viewControllers.first! as? BlueprintViewController {
                        return blueprintViewController.teardown()
                    }
                }
            }
        }
        return nil
    }

    func jobWizardViewController(viewController: JobWizardViewController, didSetScaleForBlueprintViewController blueprintViewController: BlueprintViewController) {
        if let jobBlueprintsViewControllerIndex = tabBar.items!.indexOf(setupBlueprintsTabBarItem) {
            if let jobBlueprintsViewController = (viewControllers![jobBlueprintsViewControllerIndex] as! UINavigationController).viewControllers.first! as? JobBlueprintsViewController {
                jobBlueprintsViewController.refresh()
            }
        }
    }

    deinit {
        logInfo("Deinitialize JobWizardTabBarController")
    }
}
