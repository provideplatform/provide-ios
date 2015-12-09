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
            return items[5]
        }
        return nil
    }

    private var isEditMode: Bool {
        if let _ = job {
            let hasBlueprint = job.blueprints?.count > 0
            let hasSupervisor = job.supervisors?.count > 0
            let hasInventory = job.materials?.count > 0
            let hasWorkOrders = job.workOrdersCount > 0
            return (hasBlueprint && hasSupervisor && hasInventory && hasWorkOrders) || job.status != "configuring"
        }
        return false
    }

    private var shouldRenderBlueprintSetup: Bool {
        if let job = job {
            return !isEditMode && job.blueprints.count == 0
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

        for viewController in viewControllers! {
            if viewController.isKindOfClass(JobWizardViewController) {
                (viewController as! JobWizardViewController).delegate = self
            }
        }

        tabBar.frame.size.height = 60.0

        var cropRect = tabBar.frame
        cropRect.origin.y = cropRect.size.height - tabBar.frame.height
        tabBar.backgroundImage = UIImage("bar-background")!.crop(cropRect)

        let mapPin = UIImage("map-pin")!
        tabBar.selectionIndicatorImage = mapPin.scaledToWidth(mapPin.size.width / 2.8)

        //setSelectionIndicatorImageViewFrame()
        
        selectInitialTabBarItem()
    }

//    private func setSelectionIndicatorImageViewFrame() {
//        if let selectionIndicatorImage = tabBar.selectionIndicatorImage {
//            for view in tabBar.subviews {
//                for v in view.subviews {
//                    if v.isKindOfClass(UIImageView) {
//                        if (v as! UIImageView).image == selectionIndicatorImage {
//                            v.frame = CGRectInset(v.frame, 0.0, -12.0)
//                        }
//                    }
//                }
//            }
//        }
//    }

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
        if viewController.isKindOfClass(JobReviewViewController) {
            if let job = job {
                return ["canceled", "completed"].indexOf(job.status) > -1
            }
        }
        return true
    }

    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        // no-op

        //setSelectionIndicatorImageViewFrame()
    }

    // MARK: JobWizardViewControllerDelegate

    func jobForJobWizardViewController(viewController: JobWizardViewController) -> Job! {
        return job
    }
}
