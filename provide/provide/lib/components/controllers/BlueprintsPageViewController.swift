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

class BlueprintsPageViewController: UIPageViewController,
                                    UIPageViewControllerDelegate,
                                    BlueprintViewControllerDelegate,
                                    BlueprintToolbarDelegate {

    var blueprintsPageViewControllerDelegate: BlueprintsPageViewControllerDelegate! {
        didSet {
            if let _ = blueprintsPageViewControllerDelegate {
                setViewControllers([BlueprintViewController()], direction: .Forward, animated: false, completion: nil)
                blueprintViewControllers = [BlueprintViewController : Attachment]()
                resetViewControllers()
            }
        }
    }

    private var blueprintViewControllers = [BlueprintViewController : Attachment]()

    private var job: Job! {
        return blueprintsPageViewControllerDelegate?.jobForBlueprintsPageViewController(self)
    }

    private var selectedBlueprint: Attachment! {
        if let viewController = selectedBlueprintViewController {
            if let blueprint = blueprintViewControllers[viewController] {
                return blueprint
            }
        }
        return nil
    }

    private var selectedBlueprintViewController: BlueprintViewController! {
        if blueprintViewControllers.count > 0 {
            if let viewControllers = viewControllers {
                if viewControllers.count == 1 {
                    if let viewController = viewControllers.first as? BlueprintViewController {
                        return viewController
                    }
                }
            }
        }
        return nil
    }

    private var selectedIndex = 0

    private var toolbarViewController: UIViewController!

    private var toolbar: BlueprintToolbar!

    override func awakeFromNib() {
        super.awakeFromNib()

        delegate = self

        setViewControllers([BlueprintViewController()], direction: .Forward, animated: false, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        toolbarViewController = UIStoryboard("BlueprintsPageView").instantiateViewControllerWithIdentifier("BlueprintToolbarViewController")
        toolbar = toolbarViewController.view.subviews.first! as! BlueprintToolbar

        if let toolbar = toolbar {
            toolbar.blueprintToolbarDelegate = self

            toolbar.alpha = 0.0
            toolbar.barTintColor = Color.darkBlueBackground()

            updateToolbarViewControllerFrame()
        }

        NSNotificationCenter.defaultCenter().addObserverForName("BlueprintsPageViewControllerDidImportFromDropbox") { notification in
            if let job = self.job {
                job.reload([:],
                    onSuccess: { [weak self] statusCode, mappingResult in
                        self?.resetViewControllers(.Forward, animated: true)
                    },
                    onError: { error, statusCode, responseString in

                    }
                )
            }
        }
    }

    private func updateToolbarViewControllerFrame() {
        if let toolbarViewController = toolbarViewController {
            if toolbarViewController.view.superview == nil {
                toolbarViewController.view.frame.origin.y = view.frame.size.height
                toolbarViewController.view.frame.size.width = view.frame.size.width

                view.addSubview(toolbarViewController.view)
                view.bringSubviewToFront(toolbarViewController.view)
            }

            dispatch_after_delay(0.0) {
                self.toolbar.reload()
            }
        }
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }

    func resetViewControllers(direction: UIPageViewControllerNavigationDirection = .Forward, animated: Bool = false) {
        if let viewController = self.viewControllers?.first as? BlueprintViewController {
            if viewController.blueprint == nil {
                blueprintViewControllers = [BlueprintViewController : Attachment]()
            }
        }

        if let blueprints = blueprintsPageViewControllerDelegate?.blueprintsForBlueprintsPageViewController(self) {
            for blueprint in blueprints {
                var rendered = false
                for renderedBlueprint in blueprintViewControllers.values {
                    if renderedBlueprint.id == blueprint.id {
                        rendered = true
                        break
                    }
                }

                if !rendered {
                    let blueprintViewController = UIStoryboard("Blueprint").instantiateViewControllerWithIdentifier("BlueprintViewController") as! BlueprintViewController
                    blueprintViewController.blueprintViewControllerDelegate = self

                    blueprintViewControllers[blueprintViewController] = blueprint
                }
            }
        }

        var viewControllers = [BlueprintViewController]()
        for blueprintViewController in blueprintViewControllers.keys {
            viewControllers.append(blueprintViewController)
        }

        if viewControllers.count > 0 {
            let viewController = viewControllers[selectedIndex]
            setViewControllers([viewController], direction: direction, animated: animated, completion: { complete in
                logInfo("Blueprint page view controller rendered \(viewControllers.first!)")

                self.pageViewController(self, willTransitionToViewControllers: viewControllers)
            })
        }
    }

    func seek(selectedIndex: Int!) {
        if blueprintViewControllers.count > 0 {
            var direction: UIPageViewControllerNavigationDirection = self.selectedIndex > selectedIndex ? .Reverse : .Forward
            self.selectedIndex = selectedIndex
            if selectedIndex > blueprintViewControllers.count - 1 {
                self.selectedIndex = 0
                direction = .Reverse
            }

            resetViewControllers(direction, animated: true)
        }
    }

    func next() {
        if blueprintViewControllers.count > 0 {
            var direction: UIPageViewControllerNavigationDirection = .Forward
            selectedIndex += 1
            if selectedIndex > blueprintViewControllers.count - 1 {
                selectedIndex = 0
                direction = .Reverse
            }

            resetViewControllers(direction, animated: true)
        }
    }

    func previous() {
        if blueprintViewControllers.count > 0 {
            var direction: UIPageViewControllerNavigationDirection = .Reverse
            selectedIndex -= 1
            if selectedIndex < 0 {
                selectedIndex = blueprintViewControllers.count - 1
                direction = .Forward
            }

            resetViewControllers(direction, animated: true)
        }
    }

    // MARK: UIPageViewControllerDelegate

    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
        if let toolbar = toolbar {
            dispatch_after_delay(0.0) {
                toolbar.reload()
            }
        }

//        if let _ = navigationController {
//            if pendingViewControllers.count == 1 {
//                if let viewController = pendingViewControllers.first! as? BlueprintViewController {
//                    var setTitle = false
//
//                    if let blueprint = viewController.blueprint {
//                        if let title = blueprint.filename {
//                            viewController.title = title.uppercaseString
//
//                            if let navigationItem = blueprintsPageViewControllerDelegate?.navigationItemForBlueprintsPageViewController?(self) {
//                                navigationItem.title = viewController.title
//                            }
//                            setTitle = true
//                        }
//                    }
//
//                    if !setTitle {
//                        viewController.title = nil
//                    }
//                }
//            }
//        }
    }

    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let toolbar = toolbar {
            dispatch_after_delay(0.0) {
                toolbar.reload()
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

    func toolbarForBlueprintViewController(viewController: BlueprintViewController) -> BlueprintToolbar! {
        return toolbar
    }

    func hideToolbarForBlueprintViewController(viewController: BlueprintViewController) {
        hideToolbar()
    }

    func showToolbarForBlueprintViewController(viewController: BlueprintViewController) {
        showToolbar()
    }

    // MARK: BlueprintToolbarDelegate

    func blueprintForBlueprintToolbar(toolbar: BlueprintToolbar) -> Attachment {
        if let blueprint = selectedBlueprint {
            return blueprint
        }
        return Attachment()
    }

    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetBlueprintSelectorVisibility visible: Bool) {
        view.bringSubviewToFront(self.toolbarViewController.view)

        if let blueprintViewController = selectedBlueprintViewController {
            blueprintViewController.setBlueprintSelectorVisibility(visible)
        }
    }

    func blueprintShouldBeRenderedAtIndexPath(indexPath: NSIndexPath, forBlueprintToolbar blueprintToolbar: BlueprintToolbar) {
        if indexPath.row <= blueprintViewControllers.count - 1 {
            seek(indexPath.row)
        }
    }

    func previousBlueprintShouldBeRenderedForBlueprintToolbar(toolbar: BlueprintToolbar) {
        previous()
    }

    func nextBlueprintShouldBeRenderedForBlueprintToolbar(toolbar: BlueprintToolbar) {
        next()
    }

    func previousBlueprintButtonShouldBeEnabledForBlueprintToolbar(toolbar: BlueprintToolbar) -> Bool {
        if blueprintViewControllers.count <= 1 {
            return false
        }
        return selectedIndex > 0
    }

    func nextBlueprintButtonShouldBeEnabledForBlueprintToolbar(toolbar: BlueprintToolbar) -> Bool {
        if blueprintViewControllers.count <= 1 {
            return false
        }
        return selectedIndex < blueprintViewControllers.count - 1
    }

    func selectedBlueprintForBlueprintToolbar(toolbar: BlueprintToolbar) -> Attachment! {
        if let blueprint = selectedBlueprint {
            return blueprint
        }
        return nil
    }

    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetNavigatorVisibility visible: Bool) {
        view.bringSubviewToFront(self.toolbarViewController.view)

        if let blueprintViewController = selectedBlueprintViewController {
            blueprintViewController.setNavigatorVisibility(visible)
        }
    }

    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetWorkOrdersVisibility visible: Bool, alpha: CGFloat! = nil) {
        view.bringSubviewToFront(self.toolbarViewController.view)

        if let blueprintViewController = selectedBlueprintViewController {
            blueprintViewController.setWorkOrdersVisibility(visible, alpha: alpha)
        }
    }

    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetScaleVisibility visible: Bool) {
        // no-op
    }

    func scaleCanBeSetByBlueprintToolbar(toolbar: BlueprintToolbar) -> Bool {
        return false
    }

    func newWorkOrderItemIsShownByBlueprintToolbar(toolbar: BlueprintToolbar) -> Bool {
        return false
    }

    func newWorkOrderCanBeCreatedByBlueprintToolbar(toolbar: BlueprintToolbar) -> Bool {
        return false
    }

    func newWorkOrderShouldBeCreatedByBlueprintToolbar(toolbar: BlueprintToolbar) {
//        polygonView.alpha = 1.0
//        polygonView.attachGestureRecognizer()
//
//        newWorkOrderPending = true
//
//        overrideNavigationItemForCreatingWorkOrder(false) // FIXME: pass true when polygonView has both line endpoints drawn...
    }

    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetFloorplanOptionsVisibility visible: Bool) {
        // no-op
    }

    func floorplanOptionsItemIsShownByBlueprintToolbar(toolbar: BlueprintToolbar) -> Bool {
        return false
    }
    
    func blueprintToolbar(toolbar: BlueprintToolbar, shouldPresentAlertController alertController: UIAlertController) {
        navigationController!.presentViewController(alertController, animated: true)
    }

    private func showToolbar() {
        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: {
                if let toolbar = self.toolbar {
                    toolbar.alpha = 1.0
                    self.toolbarViewController.view.frame.origin.y = self.view.frame.height - toolbar.frame.height
                }
            },
            completion: { completed in
                
            }
        )
    }

    private func hideToolbar() {
        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: {
                if let toolbar = self.toolbar {
                    toolbar.alpha = 0.0
                    self.toolbarViewController.view.frame.origin.y = self.view.frame.height

                }
            },
            completion: { completed in

            }
        )
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        print("deinit page view controller")
    }
}
