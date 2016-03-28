//
//  BlueprintsPageViewController.swift
//  provide
//
//  Created by Kyle Thomas on 3/19/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol BlueprintsPageViewControllerDelegate {
    optional func navigationItemForBlueprintsPageViewController(viewController: BlueprintsPageViewController) -> UINavigationItem!
    func jobForBlueprintsPageViewController(viewController: BlueprintsPageViewController) -> Job!
    func blueprintsForBlueprintsPageViewController(viewController: BlueprintsPageViewController) -> [Attachment]
}

class BlueprintsPageViewController: UIPageViewController, UIPageViewControllerDelegate, BlueprintViewControllerDelegate {

    var blueprintsPageViewControllerDelegate: BlueprintsPageViewControllerDelegate! {
        didSet {
            if let _ = blueprintsPageViewControllerDelegate {
                resetViewControllers()
            }
        }
    }

    private var blueprintViewControllers = [BlueprintViewController : Attachment]()

    private var job: Job! {
        return blueprintsPageViewControllerDelegate?.jobForBlueprintsPageViewController(self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        delegate = self

        setViewControllers([BlueprintViewController()], direction: .Forward, animated: false, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }

    func resetViewControllers() {
        blueprintViewControllers = [BlueprintViewController : Attachment]()

        for blueprint in blueprintsPageViewControllerDelegate.blueprintsForBlueprintsPageViewController(self) {
            let blueprintViewController = UIStoryboard("Blueprint").instantiateViewControllerWithIdentifier("BlueprintViewController") as! BlueprintViewController
            blueprintViewController.blueprintViewControllerDelegate = self

            blueprintViewControllers[blueprintViewController] = blueprint
        }

        var viewControllers = [BlueprintViewController]()
        for blueprintViewController in blueprintViewControllers.keys {
            viewControllers.append(blueprintViewController)
        }

        if viewControllers.count > 0 {
            setViewControllers([viewControllers.first!], direction: .Forward, animated: false, completion: { complete in
                logInfo("Blueprint page view controller rendered \(viewControllers.first!)")

                self.pageViewController(self, willTransitionToViewControllers: viewControllers)
            })
        }
    }

    // MARK: UIPageViewControllerDelegate

    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
        if let _ = navigationController {
            if pendingViewControllers.count == 1 {
                if let viewController = pendingViewControllers.first! as? BlueprintViewController {
                    var setTitle = false

                    if let blueprint = viewController.blueprint {
                        if let title = blueprint.filename {
                            viewController.title = title.uppercaseString

                            if let navigationItem = blueprintsPageViewControllerDelegate?.navigationItemForBlueprintsPageViewController?(self) {
                                navigationItem.title = viewController.title
                            }
                            setTitle = true
                        }
                    }

                    if !setTitle {
                        viewController.title = nil
                    }
                }
            }
        }
    }

    // MARK: BlueprintViewControllerDelegate

    func blueprintForBlueprintViewController(viewController: BlueprintViewController) -> Attachment! {
        if let blueprint = blueprintViewControllers[viewController] {
            return blueprint
        }
        return nil
    }

    func jobForBlueprintViewController(viewController: BlueprintViewController) -> Job! {
        return job
    }

    func modeForBlueprintViewController(viewController: BlueprintViewController) -> BlueprintViewController.Mode! {
        return job == nil || !job.isPunchlist ? .Setup : .WorkOrders
    }

    func blueprintImageForBlueprintViewController(viewController: BlueprintViewController) -> UIImage! {
//        if let image = blueprintPreviewImageView?.image {
//            return image
//        }
        return nil
    }

    func scaleWasSetForBlueprintViewController(viewController: BlueprintViewController) {
        //delegate?.jobBlueprintsViewController(self, didSetScaleForBlueprintViewController: viewController)
    }

    func scaleCanBeSetByBlueprintViewController(viewController: BlueprintViewController) -> Bool {
        if job != nil && job.isCommercial {
            for provider in currentUser().providers {
                if job.hasSupervisor(provider) {
                    return true
                }
            }
        } else if job != nil && (job.isResidential || job.isPunchlist) {
            return false
        }
        return false
    }

    func newWorkOrderCanBeCreatedByBlueprintViewController(viewController: BlueprintViewController) -> Bool {
        return job == nil ? false : !job.isPunchlist
    }

    func navigationControllerForBlueprintViewController(viewController: BlueprintViewController) -> UINavigationController! {
        return navigationController
    }

    func estimateForBlueprintViewController(viewController: BlueprintViewController) -> Estimate! {
        return nil
    }

    func areaSelectorIsAvailableForBlueprintViewController(viewController: BlueprintViewController) -> Bool {
        return false
    }

    func blueprintViewControllerCanDropWorkOrderPin(viewController: BlueprintViewController) -> Bool {
        return job == nil ? false : job.isPunchlist
    }

    deinit {
        print("deinit page view controller")
    }
}
