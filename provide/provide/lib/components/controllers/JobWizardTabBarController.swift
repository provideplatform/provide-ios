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
                                 JobWizardViewControllerDelegate,
                                 TaskListViewControllerDelegate {

    weak var job: Job! {
        didSet {
            refresh()
        }
    }

    private func refresh() {
        if let job = job {
            navigationItem.title = job.name
            //navigationItem.prompt = job.status

            navigationItem.rightBarButtonItems = [taskListItem]

            if job.isResidential || job.isPunchlist {
                viewControllers?.removeAtIndex(3)
                viewControllers?.removeAtIndex(2)
                viewControllers?.removeAtIndex(1)

                if job.isResidential {
                    if let viewController = viewControllers?.first {
                        viewController.title = "Floorplan"
                    }
                }
            }

            if job.status == "pending_completion" || job.status == "completed" || job.status == "canceled" {
                if let count = viewControllers?.count {
                    viewControllers?.removeAtIndex(count - 1)
                }

                let reviewNavigationController = UIStoryboard("JobWizard").instantiateViewControllerWithIdentifier("JobReviewNavigationController")
                viewControllers?.append(reviewNavigationController)
            }

            if let jobBlueprintsViewControllerIndex = tabBar.items!.indexOf(setupBlueprintsTabBarItem) {
                if let jobBlueprintsViewController = (viewControllers![jobBlueprintsViewControllerIndex] as! UINavigationController).viewControllers.first! as? JobBlueprintsViewController {
                    jobBlueprintsViewController.refresh()
                }
            }

            if job.supervisors == nil {
                job.reloadSupervisors(
                    { statusCode, mappingResult in

                    },
                    onError: { error, statusCode, responseString in

                    }
                )
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
            let index = job.isCommercial ? 1 : -1
            if index != -1 {
                return items[index]
            }
        }
        return nil
    }

    private var setupInventoryTabBarItem: UITabBarItem! {
        if let items = tabBar.items {
            let index = job.isCommercial ? 2 : -1
            if index != -1 {
                return items[index]
            }
        }
        return nil
    }

    private var setupWorkOrdersTabBarItem: UITabBarItem! {
        if let items = tabBar.items {
            let index = job.isCommercial ? 3 : (job.isResidential || job.isPunchlist ? 1 : -1)
            if index != -1 {
                return items[index]
            }
        }
        return nil
    }

    private var manageJobTabBarItem: UITabBarItem! {
        if let items = tabBar.items {
            let index = job.isCommercial ? 4 : (job.isResidential || job.isPunchlist ? 1 : -1)
            if index != -1 {
                return items[index]
            }
        }
        return nil
    }

    private var reviewTabBarItem: UITabBarItem! {
        if let items = tabBar.items {
            let index = job.isCommercial ? 4 : (job.isResidential || job.isPunchlist ? 2 : -1)
            if index != -1 {
                return items[index]
            }
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
            if isEditMode {
                return false
            }
            if !hasBlueprint {
                return true
            }
            if job.isCommercial {
                return !hasScale
            } else if job.isResidential || job.isPunchlist {
//                for annotation in job.blueprint.annotations {
//                    if annotation.workOrderId == 0 {
//                        return true
//                    }
//                }
                return job.status == "configuring"
            }
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
            return !isEditMode && !shouldRenderBlueprintSetup && job.workOrdersCount == 0
        }
        return false
    }

    private var shouldRenderManageJob: Bool {
        return isEditMode
    }

    private var shouldRenderReviewAndComplete: Bool {
        if let job = job {
            return job.isReviewMode
        }
        return false
    }

    private var taskListItem: UIBarButtonItem! {
        let taskListIconImage = FAKFontAwesome.tasksIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0)).imageWithRenderingMode(.AlwaysTemplate)
        let taskListItem = UIBarButtonItem(image: taskListIconImage, style: .Plain, target: self, action: "showTaskList:")
        taskListItem.tintColor = UIColor.whiteColor()
        return taskListItem
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

        NSNotificationCenter.defaultCenter().addObserverForName("JobDidTransitionToPendingCompletion") { notification in
            if let job = self.job {
                if let changedJob = notification.object {
                    if job.id == changedJob.id {
                        self.job = changedJob as! Job
                        self.selectInitialTabBarItem()
                        if let reviewNavigationController = self.viewControllers!.last! as? UINavigationController {
                            let rootViewController = reviewNavigationController.viewControllers.first!
                            if rootViewController.isKindOfClass(JobReviewViewController) {
                                (rootViewController as! JobReviewViewController).job = self.job
                            }
                        }
                    }
                }
            }
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }

    func showTaskList(sender: UIBarButtonItem) {
        let taskListNavigationController = UIStoryboard("TaskList").instantiateInitialViewController() as! UINavigationController
        (taskListNavigationController.viewControllers.first! as! TaskListViewController).taskListViewControllerDelegate = self
        taskListNavigationController.modalPresentationStyle = .Popover
        taskListNavigationController.preferredContentSize = CGSizeMake(300, 250)
        taskListNavigationController.popoverPresentationController!.barButtonItem = sender
        taskListNavigationController.popoverPresentationController!.permittedArrowDirections = [.Right]
        taskListNavigationController.popoverPresentationController!.canOverlapSourceViewRect = false
        presentViewController(taskListNavigationController, animated: true)
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
        tabBar.selectionIndicatorImage = mapPin.scaledToWidth(mapPin.size.width / 4)

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

        if shouldRenderReviewAndComplete {
            item = reviewTabBarItem
        } else if shouldRenderManageJob {
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
                        let shouldSelectViewController = ["pending_completion", "canceled", "completed"].indexOf(job.status) != nil
                        if shouldSelectViewController {
                            (rootViewController as! JobReviewViewController).job = job
                        }
                        return shouldSelectViewController
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
                        if let blueprintImage = jobBlueprintsViewController.teardownBlueprintViewController() {
                            return blueprintImage
                        }
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

    // MARK: TaskListViewControllerDelegate

    func jobForTaskListViewController(viewController: TaskListViewController) -> Job! {
        return job
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        logInfo("Deinitialize JobWizardTabBarController")
    }
}
