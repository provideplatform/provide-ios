//
//  FloorplansPageViewController.swift
//  provide
//
//  Created by Kyle Thomas on 3/19/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol FloorplansPageViewControllerDelegate {
    optional func navigationItemForFloorplansPageViewController(viewController: FloorplansPageViewController) -> UINavigationItem!
    func jobForFloorplansPageViewController(viewController: FloorplansPageViewController) -> Job!
    func floorplansForFloorplansPageViewController(viewController: FloorplansPageViewController) -> Set<Floorplan>
}

class FloorplansPageViewController: UIPageViewController,
                                    UIPageViewControllerDelegate,
                                    FloorplanViewControllerDelegate,
                                    FloorplanToolbarDelegate {

    var floorplansPageViewControllerDelegate: FloorplansPageViewControllerDelegate! {
        didSet {
            if let _ = floorplansPageViewControllerDelegate {
                setViewControllers([FloorplanViewController()], direction: .Forward, animated: false, completion: nil)
                floorplanViewControllers = Set<FloorplanViewController>() //[FloorplanViewController : Attachment]()
                resetViewControllers()
            }
        }
    }

    private var floorplanViewControllers = Set<FloorplanViewController>()

    private var job: Job! {
        return floorplansPageViewControllerDelegate?.jobForFloorplansPageViewController(self)
    }

    private var selectedFloorplan: Floorplan! {
        if let viewController = selectedFloorplanViewController {
            if let index = floorplanViewControllers.indexOf(viewController) {
                return floorplanViewControllers[index].floorplan
            }
        }
        return nil
    }

    private var selectedFloorplanViewController: FloorplanViewController! {
        if floorplanViewControllers.count > 0 {
            if selectedIndex <= floorplanViewControllers.count - 1 {
                return Array(floorplanViewControllers).sort({ $0.floorplan.id < $1.floorplan.id })[selectedIndex] // HACK
            }
//            if let viewControllers = viewControllers {
//                if viewControllers.count == 1 {
//                    if let viewController = viewControllers.first as? FloorplanViewController {
//                        return viewController
//                    }
//                }
//            }
        }
        return nil
    }

    private var selectedIndex = 0

    private var toolbarViewController: UIViewController!

    private var toolbar: FloorplanToolbar!

    override func awakeFromNib() {
        super.awakeFromNib()

        delegate = self

        setViewControllers([FloorplanViewController()], direction: .Forward, animated: false, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        toolbarViewController = UIStoryboard("FloorplansPageView").instantiateViewControllerWithIdentifier("FloorplanToolbarViewController")
        toolbar = toolbarViewController.view.subviews.first! as! FloorplanToolbar

        if let toolbar = toolbar {
            toolbar.floorplanToolbarDelegate = self

            toolbar.alpha = 0.0
            toolbar.barTintColor = Color.darkBlueBackground()

            updateToolbarViewControllerFrame()
        }

        NSNotificationCenter.defaultCenter().addObserverForName("FloorplansPageViewControllerDidImportFromDropbox") { notification in
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
        if let viewController = self.viewControllers?.first as? FloorplanViewController {
            if viewController.floorplan == nil {
                floorplanViewControllers = Set<FloorplanViewController>()
            }
        }

        if let floorplans = floorplansPageViewControllerDelegate?.floorplansForFloorplansPageViewController(self) {
            for floorplan in floorplans {
                var rendered = false
                for renderedFloorplan in floorplanViewControllers.map({ $0.floorplan }) {
                    if renderedFloorplan.id == floorplan.id {
                        rendered = true
                        break
                    }
                }

                if !rendered {
                    let floorplanViewController = UIStoryboard("Floorplan").instantiateViewControllerWithIdentifier("FloorplanViewController") as! FloorplanViewController
                    floorplanViewController.floorplanViewControllerDelegate = self
                    floorplanViewController.floorplan = floorplan

                    floorplanViewControllers.insert(floorplanViewController)
                }
            }

            if floorplanViewControllers.count > 0 {
                if let index = floorplanViewControllers.indexOf(selectedFloorplanViewController) {
                    let viewController = floorplanViewControllers[index]
                    setViewControllers([viewController], direction: direction, animated: animated, completion: { complete in
                        self.pageViewController(self, willTransitionToViewControllers: [viewController])
                    })
                }
            }
        }
    }

    func seek(selectedIndex: Int!) {
        if floorplanViewControllers.count > 0 {
            var direction: UIPageViewControllerNavigationDirection = self.selectedIndex > selectedIndex ? .Reverse : .Forward
            self.selectedIndex = selectedIndex
            if selectedIndex > floorplanViewControllers.count - 1 {
                self.selectedIndex = 0
                direction = .Reverse
            }

            resetViewControllers(direction, animated: true)
        }
    }

    func next() {
        if floorplanViewControllers.count > 0 {
            var direction: UIPageViewControllerNavigationDirection = .Forward
            selectedIndex += 1
            if selectedIndex > floorplanViewControllers.count - 1 {
                selectedIndex = 0
                direction = .Reverse
            }

            resetViewControllers(direction, animated: true)
        }
    }

    func previous() {
        if floorplanViewControllers.count > 0 {
            var direction: UIPageViewControllerNavigationDirection = .Reverse
            selectedIndex -= 1
            if selectedIndex < 0 {
                selectedIndex = floorplanViewControllers.count - 1
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
    }

    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let toolbar = toolbar {
            dispatch_after_delay(0.0) {
                toolbar.reload()
            }
        }
    }

    // MARK: FloorplanViewControllerDelegate

    func floorplanForFloorplanViewController(viewController: FloorplanViewController) -> Floorplan! {
        if let index = floorplanViewControllers.indexOf(viewController) {
            return floorplanViewControllers[index].floorplan
        }
        return nil
    }

    func jobForFloorplanViewController(viewController: FloorplanViewController) -> Job! {
        return job
    }

    func modeForFloorplanViewController(viewController: FloorplanViewController) -> FloorplanViewController.Mode! {
        return job == nil || !job.isPunchlist ? .Setup : .WorkOrders
    }

    func floorplanImageForFloorplanViewController(viewController: FloorplanViewController) -> UIImage! {
//        if let image = floorplanPreviewImageView?.image {
//            return image
//        }
        return nil
    }

    func scaleWasSetForFloorplanViewController(viewController: FloorplanViewController) {
        //delegate?.jobFloorplansViewController(self, didSetScaleForFloorplanViewController: viewController)
    }

    func scaleCanBeSetByFloorplanViewController(viewController: FloorplanViewController) -> Bool {
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

    func newWorkOrderCanBeCreatedByFloorplanViewController(viewController: FloorplanViewController) -> Bool {
        return job == nil ? false : !job.isPunchlist
    }

    func navigationControllerForFloorplanViewController(viewController: FloorplanViewController) -> UINavigationController! {
        return navigationController
    }

    func areaSelectorIsAvailableForFloorplanViewController(viewController: FloorplanViewController) -> Bool {
        return false
    }

    func floorplanViewControllerCanDropWorkOrderPin(viewController: FloorplanViewController) -> Bool {
        return job == nil ? false : job.isPunchlist
    }

    func toolbarForFloorplanViewController(viewController: FloorplanViewController) -> FloorplanToolbar! {
        return toolbar
    }

    func hideToolbarForFloorplanViewController(viewController: FloorplanViewController) {
        hideToolbar()
    }

    func showToolbarForFloorplanViewController(viewController: FloorplanViewController) {
        showToolbar()
    }

    // MARK: FloorplanToolbarDelegate

    func floorplanForFloorplanToolbar(toolbar: FloorplanToolbar) -> Floorplan {
        if let floorplan = selectedFloorplan {
            return floorplan
        }
        return Floorplan()
    }

    func floorplanToolbar(toolbar: FloorplanToolbar, shouldSetFloorplanSelectorVisibility visible: Bool) {
        view.bringSubviewToFront(self.toolbarViewController.view)

        if let floorplanViewController = selectedFloorplanViewController {
            floorplanViewController.setFloorplanSelectorVisibility(visible)
        }
    }

    func floorplanShouldBeRenderedAtIndexPath(indexPath: NSIndexPath, forFloorplanToolbar floorplanToolbar: FloorplanToolbar) {
        if indexPath.row <= floorplanViewControllers.count - 1 {
            seek(indexPath.row)
        }
    }

    func previousFloorplanShouldBeRenderedForFloorplanToolbar(toolbar: FloorplanToolbar) {
        previous()
    }

    func nextFloorplanShouldBeRenderedForFloorplanToolbar(toolbar: FloorplanToolbar) {
        next()
    }

    func previousFloorplanButtonShouldBeEnabledForFloorplanToolbar(toolbar: FloorplanToolbar) -> Bool {
        if floorplanViewControllers.count <= 1 {
            return false
        }
        return selectedIndex > 0
    }

    func nextFloorplanButtonShouldBeEnabledForFloorplanToolbar(toolbar: FloorplanToolbar) -> Bool {
        if floorplanViewControllers.count <= 1 {
            return false
        }
        return selectedIndex < floorplanViewControllers.count - 1
    }

    func selectedFloorplanForFloorplanToolbar(toolbar: FloorplanToolbar) -> Floorplan! {
        if let floorplan = selectedFloorplan {
            return floorplan
        }
        return nil
    }

    func floorplanToolbar(toolbar: FloorplanToolbar, shouldSetNavigatorVisibility visible: Bool) {
        view.bringSubviewToFront(self.toolbarViewController.view)

        if let floorplanViewController = selectedFloorplanViewController {
            floorplanViewController.setNavigatorVisibility(visible)
        }
    }

    func floorplanToolbar(toolbar: FloorplanToolbar, shouldSetWorkOrdersVisibility visible: Bool, alpha: CGFloat! = nil) {
        view.bringSubviewToFront(self.toolbarViewController.view)

        if let floorplanViewController = selectedFloorplanViewController {
            floorplanViewController.setWorkOrdersVisibility(visible, alpha: alpha)
        }
    }

    func floorplanToolbar(toolbar: FloorplanToolbar, shouldSetScaleVisibility visible: Bool) {
        // no-op
    }

    func scaleCanBeSetByFloorplanToolbar(toolbar: FloorplanToolbar) -> Bool {
        return false
    }

    func newWorkOrderItemIsShownByFloorplanToolbar(toolbar: FloorplanToolbar) -> Bool {
        return false
    }

    func newWorkOrderCanBeCreatedByFloorplanToolbar(toolbar: FloorplanToolbar) -> Bool {
        return false
    }

    func newWorkOrderShouldBeCreatedByFloorplanToolbar(toolbar: FloorplanToolbar) {
//        polygonView.alpha = 1.0
//        polygonView.attachGestureRecognizer()
//
//        newWorkOrderPending = true
//
//        overrideNavigationItemForCreatingWorkOrder(false) // FIXME: pass true when polygonView has both line endpoints drawn...
    }

    func floorplanToolbar(toolbar: FloorplanToolbar, shouldSetFloorplanOptionsVisibility visible: Bool) {
        // no-op
    }

    func floorplanOptionsItemIsShownByFloorplanToolbar(toolbar: FloorplanToolbar) -> Bool {
        return false
    }
    
    func floorplanToolbar(toolbar: FloorplanToolbar, shouldPresentAlertController alertController: UIAlertController) {
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
