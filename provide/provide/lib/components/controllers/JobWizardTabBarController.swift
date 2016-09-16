//
//  JobWizardTabBarController.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import FontAwesomeKit
import KTSwiftExtensions
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class JobWizardTabBarController: UITabBarController,
                                 UITabBarControllerDelegate,
                                 JobWizardViewControllerDelegate,
                                 TaskListViewControllerDelegate {

    weak var job: Job! {
        didSet {
            refresh()
        }
    }

    fileprivate func refresh() {
        if let job = job {
            navigationItem.title = job.name
            //navigationItem.prompt = job.status

            navigationItem.rightBarButtonItems = [taskListItem]

            if job.isResidential || job.isPunchlist {
                viewControllers?.remove(at: 3)
                viewControllers?.remove(at: 2)
                viewControllers?.remove(at: 1)

                if job.isResidential {
                    if let viewController = viewControllers?.first {
                        viewController.title = "Floorplan"
                    }
                }
            }

            if job.status == "pending_completion" || job.status == "completed" || job.status == "canceled" {
                if let count = viewControllers?.count {
                    viewControllers?.remove(at: count - 1)
                }

                let reviewNavigationController = UIStoryboard("JobWizard").instantiateViewController(withIdentifier: "JobReviewNavigationController")
                viewControllers?.append(reviewNavigationController)
            }

            if let jobFloorplansViewControllerIndex = tabBar.items!.index(of: setupFloorplansTabBarItem) {
                if let jobFloorplansViewController = (viewControllers![jobFloorplansViewControllerIndex] as! UINavigationController).viewControllers.first! as? JobFloorplansViewController {
                    jobFloorplansViewController.refresh()
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

    fileprivate var setupFloorplansTabBarItem: UITabBarItem! {
        if let items = tabBar.items {
            return items[0]
        }
        return nil
    }

    fileprivate var setupTeamTabBarItem: UITabBarItem! {
        if let items = tabBar.items {
            let index = job.isCommercial ? 1 : -1
            if index != -1 {
                return items[index]
            }
        }
        return nil
    }

    fileprivate var setupInventoryTabBarItem: UITabBarItem! {
        if let items = tabBar.items {
            let index = job.isCommercial ? 2 : -1
            if index != -1 {
                return items[index]
            }
        }
        return nil
    }

    fileprivate var setupWorkOrdersTabBarItem: UITabBarItem! {
        if let items = tabBar.items {
            let index = job.isCommercial ? 3 : (job.isResidential || job.isPunchlist ? 1 : -1)
            if index != -1 {
                return items[index]
            }
        }
        return nil
    }

    fileprivate var manageJobTabBarItem: UITabBarItem! {
        if let items = tabBar.items {
            let index = job.isCommercial ? 4 : (job.isResidential || job.isPunchlist ? 1 : -1)
            if index != -1 {
                return items[index]
            }
        }
        return nil
    }

    fileprivate var reviewTabBarItem: UITabBarItem! {
        if let items = tabBar.items {
            let index = job.isCommercial ? 4 : (job.isResidential || job.isPunchlist ? 2 : -1)
            if index != -1 {
                return items[index]
            }
        }
        return nil
    }

    fileprivate var isEditMode: Bool {
        if let _ = job {
            let hasFloorplan = job.floorplans?.count > 0
            let hasScale = hasFloorplan && job.floorplans?.first!.scale != nil
            let hasSupervisor = job.supervisors?.count > 0
            let hasInventory = job.materials?.count > 0
            let hasWorkOrders = job.workOrdersCount > 0
            return !job.isWizardMode && ((hasFloorplan && hasScale && hasSupervisor && hasInventory && hasWorkOrders) || job.status != "configuring")
        }
        return false
    }

    fileprivate var shouldRenderFloorplanSetup: Bool {
        if let job = job {
            let hasFloorplan = job.floorplans?.count > 0
            let hasScale = hasFloorplan && job.floorplans?.first!.scale != nil
            if isEditMode {
                return false
            }
            if !hasFloorplan {
                return true
            }
            if job.isCommercial {
                return !hasScale
            } else if job.isResidential || job.isPunchlist {
//                for annotation in job.floorplan.annotations {
//                    if annotation.workOrderId == 0 {
//                        return true
//                    }
//                }
                return job.status == "configuring"
            }
        }
        return false
    }

    fileprivate var shouldRenderTeamSetup: Bool {
        if let job = job {
            if let supervisors = job.supervisors {
                return !isEditMode && supervisors.count == 0
            }
        }
        return false
    }

    fileprivate var shouldRenderInventorySetup: Bool {
        if let job = job {
            if let materials = job.materials {
                return !isEditMode && materials.count == 0
            }
        }
        return false
    }

    fileprivate var shouldRenderWorkOrderSetup: Bool {
        if let job = job {
            return !isEditMode && !shouldRenderFloorplanSetup && job.workOrdersCount == 0
        }
        return false
    }

    fileprivate var shouldRenderManageJob: Bool {
        return isEditMode
    }

    fileprivate var shouldRenderReviewAndComplete: Bool {
        if let job = job {
            return job.isReviewMode
        }
        return false
    }

    fileprivate var taskListItem: UIBarButtonItem! {
        let taskListIconImage = FAKFontAwesome.tasksIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0)).withRenderingMode(.alwaysTemplate)
        let taskListItem = UIBarButtonItem(image: taskListIconImage, style: .plain, target: self, action: #selector(JobWizardTabBarController.showTaskList(_:)))
        taskListItem.tintColor = Color.applicationDefaultBarButtonItemTintColor()
        return taskListItem
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        dispatch_after_delay(0.0) { [weak self] in
            for viewController in self!.viewControllers! {
                if viewController is JobWizardViewController {
                    (viewController as! JobWizardViewController).jobWizardViewControllerDelegate = self!
                }
            }

            self!.selectInitialTabBarItem()
        }

        setupTabBarAppearence()

        NotificationCenter.default.addObserverForName("JobDidTransitionToPendingCompletion") { notification in
            if let job = self.job {
                if let changedJob = notification.object {
                    if job.id == (changedJob as AnyObject).id {
                        self.job = changedJob as! Job
                        self.selectInitialTabBarItem()
                        if let reviewNavigationController = self.viewControllers!.last! as? UINavigationController {
                            let rootViewController = reviewNavigationController.viewControllers.first!
                            if rootViewController is JobReviewViewController {
                                (rootViewController as! JobReviewViewController).job = self.job
                            }
                        }
                    }
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    func showTaskList(_ sender: UIBarButtonItem) {
        let taskListNavigationController = UIStoryboard("TaskList").instantiateInitialViewController() as! UINavigationController
        (taskListNavigationController.viewControllers.first! as! TaskListViewController).taskListViewControllerDelegate = self
        taskListNavigationController.modalPresentationStyle = .popover
        taskListNavigationController.preferredContentSize = CGSize(width: 300, height: 250)
        taskListNavigationController.popoverPresentationController!.barButtonItem = sender
        taskListNavigationController.popoverPresentationController!.permittedArrowDirections = [.right]
        taskListNavigationController.popoverPresentationController!.canOverlapSourceViewRect = false
        presentViewController(taskListNavigationController, animated: true)
    }

    func dismiss(_ sender: UIBarButtonItem) {
        let _ = navigationController?.popViewController(animated: true)
    }

    fileprivate func setupTabBarAppearence() {
        //tabBar.frame.size.height = 60.0

        //var cropRect = tabBar.frame
        //cropRect.origin.y = cropRect.size.height - tabBar.frame.height
        //tabBar.backgroundImage = UIImage("bar-background")!.crop(cropRect)

        let mapPin = UIImage("map-pin")!
        tabBar.selectionIndicatorImage = mapPin.scaledToWidth(mapPin.size.width / 4)

        refreshSelectionIndicatorImageViewFrame()
    }

    fileprivate func refreshSelectionIndicatorImageViewFrame() {
        if let selectionIndicatorImage = tabBar.selectionIndicatorImage {
            for view in tabBar.subviews {
                for v in view.subviews {
                    if v.isKind(of: UIImageView.self) {
                        if (v as! UIImageView).image == selectionIndicatorImage {
                            //v.frame = CGRectInset(v.frame, 0.0, -12.0)
                            view.sendSubview(toBack: v)
                        }
                    }
                }
            }
        }
    }

    fileprivate func selectInitialTabBarItem() {
        var item: UITabBarItem?

        if shouldRenderReviewAndComplete {
            item = reviewTabBarItem
        } else if shouldRenderManageJob {
            item = manageJobTabBarItem
        } else if shouldRenderFloorplanSetup {
            item = setupFloorplansTabBarItem
        } else if shouldRenderTeamSetup {
            item = setupTeamTabBarItem
        } else if shouldRenderInventorySetup {
            item = setupInventoryTabBarItem
        } else if shouldRenderWorkOrderSetup {
            item = setupWorkOrdersTabBarItem
        }

        if let item = item {
            selectedIndex = tabBar.items!.index(of: item)!
        }
    }

    // MARK: UITabBarControllerDelegate

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let job = job {
            if viewController.isKind(of: UINavigationController.self) {
                if (viewController as! UINavigationController).viewControllers.count == 1 {
                    let rootViewController = (viewController as! UINavigationController).viewControllers.first!
                    if rootViewController.isKind(of: JobReviewViewController.self) {
                        let shouldSelectViewController = ["pending_completion", "canceled", "completed"].index(of: job.status) != nil
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

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        refreshSelectionIndicatorImageViewFrame()
    }

    // MARK: JobWizardViewControllerDelegate

    func jobForJobWizardViewController(_ viewController: JobWizardViewController) -> Job! {
        return job
    }

    func floorplanImageForJobWizardViewController(_ viewController: JobWizardViewController) -> UIImage! {
        if viewController.isKind(of: UINavigationController.self) {
            let rootViewController = (viewController as UINavigationController).viewControllers.first!
            if let _ = rootViewController as? FloorplanViewController {
                if let jobFloorplansViewControllerIndex = tabBar.items!.index(of: setupFloorplansTabBarItem) {
                    if let jobFloorplansViewController = (viewControllers![jobFloorplansViewControllerIndex] as! UINavigationController).viewControllers.first! as? JobFloorplansViewController {
                        if let floorplanImage = jobFloorplansViewController.teardownFloorplanViewController() {
                            return floorplanImage
                        }
                    }
                }
            } else if let _ = rootViewController as? JobFloorplansViewController {
                if let floorplanViewControllerIndex = tabBar.items!.index(of: setupWorkOrdersTabBarItem) {
                    if let floorplanViewController = (viewControllers![floorplanViewControllerIndex] as! UINavigationController).viewControllers.first! as? FloorplanViewController {
                        return floorplanViewController.teardown()
                    }
                }
            }
        }
        return nil
    }

    func jobWizardViewController(_ viewController: JobWizardViewController, didSetScaleForFloorplanViewController floorplanViewController: FloorplanViewController) {
        if let jobFloorplansViewControllerIndex = tabBar.items!.index(of: setupFloorplansTabBarItem) {
            if let jobFloorplansViewController = (viewControllers![jobFloorplansViewControllerIndex] as! UINavigationController).viewControllers.first! as? JobFloorplansViewController {
                jobFloorplansViewController.refresh()
            }
        }
    }

    // MARK: TaskListViewControllerDelegate

    func jobForTaskListViewController(_ viewController: TaskListViewController) -> Job! {
        return job
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        logInfo("Deinitialize JobWizardTabBarController")
    }
}
