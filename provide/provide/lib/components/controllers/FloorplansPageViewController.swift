//
//  FloorplansPageViewController.swift
//  provide
//
//  Created by Kyle Thomas on 3/19/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

@objc
protocol FloorplansPageViewControllerDelegate {
    @objc optional func navigationItemForFloorplansPageViewController(_ viewController: FloorplansPageViewController) -> UINavigationItem!
    func jobForFloorplansPageViewController(_ viewController: FloorplansPageViewController) -> Job!
    func floorplansForFloorplansPageViewController(_ viewController: FloorplansPageViewController) -> Set<Floorplan>
}

class FloorplansPageViewController: UIPageViewController,
                                    UIPageViewControllerDelegate,
                                    FloorplanViewControllerDelegate,
                                    FloorplanToolbarDelegate {

    var floorplansPageViewControllerDelegate: FloorplansPageViewControllerDelegate! {
        didSet {
            if let _ = floorplansPageViewControllerDelegate {
                setViewControllers([FloorplanViewController()], direction: .forward, animated: false, completion: nil)
                floorplanViewControllers = Set<FloorplanViewController>() //[FloorplanViewController : Attachment]()
                resetViewControllers()
            }
        }
    }

    fileprivate var floorplanViewControllers = Set<FloorplanViewController>()

    fileprivate var job: Job! {
        return floorplansPageViewControllerDelegate?.jobForFloorplansPageViewController(self)
    }

    fileprivate var selectedFloorplan: Floorplan! {
        if let viewController = selectedFloorplanViewController {
            if let index = floorplanViewControllers.index(of: viewController) {
                return floorplanViewControllers[index].floorplan
            }
        }
        return nil
    }

    fileprivate var selectedFloorplanViewController: FloorplanViewController! {
        if floorplanViewControllers.count > 0 {
            if selectedIndex <= floorplanViewControllers.count - 1 {
                return Array(floorplanViewControllers).sorted(by: { $0.floorplan.id < $1.floorplan.id })[selectedIndex] // HACK
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

    fileprivate var selectedIndex = 0

    fileprivate var toolbarViewController: UIViewController!

    fileprivate var toolbar: FloorplanToolbar!

    override func awakeFromNib() {
        super.awakeFromNib()

        delegate = self

        setViewControllers([FloorplanViewController()], direction: .forward, animated: false, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        toolbarViewController = UIStoryboard("FloorplansPageView").instantiateViewController(withIdentifier: "FloorplanToolbarViewController")
        toolbar = toolbarViewController.view.subviews.first! as! FloorplanToolbar

        if let toolbar = toolbar {
            toolbar.floorplanToolbarDelegate = self

            toolbar.alpha = 0.0
            toolbar.barTintColor = Color.darkBlueBackground()

            updateToolbarViewControllerFrame()
        }

        NotificationCenter.default.addObserverForName("FloorplansPageViewControllerDidImportFromDropbox") { notification in
            if let job = self.job {
                job.reload([:],
                    onSuccess: { [weak self] statusCode, mappingResult in
                        self?.resetViewControllers(.forward, animated: true)
                    },
                    onError: { error, statusCode, responseString in

                    }
                )
            }
        }
    }

    fileprivate func updateToolbarViewControllerFrame() {
        if let toolbarViewController = toolbarViewController {
            if toolbarViewController.view.superview == nil {
                toolbarViewController.view.frame.origin.y = view.frame.size.height
                toolbarViewController.view.frame.size.width = view.frame.size.width

                view.addSubview(toolbarViewController.view)
                view.bringSubview(toFront: toolbarViewController.view)
            }

            dispatch_after_delay(0.0) {
                self.toolbar.reload()
            }
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    func resetViewControllers(_ direction: UIPageViewControllerNavigationDirection = .forward, animated: Bool = false) {
        if let viewController = self.viewControllers?.first as? FloorplanViewController {
            if viewController.floorplan == nil {
                floorplanViewControllers = Set<FloorplanViewController>()
            }
        }

        if let floorplans = floorplansPageViewControllerDelegate?.floorplansForFloorplansPageViewController(self) {
            for floorplan in floorplans {
                var rendered = false
                for renderedFloorplan in floorplanViewControllers.map({ $0.floorplan }) {
                    if renderedFloorplan?.id == floorplan.id {
                        rendered = true
                        break
                    }
                }

                if !rendered {
                    let floorplanViewController = UIStoryboard("Floorplan").instantiateViewController(withIdentifier: "FloorplanViewController") as! FloorplanViewController
                    floorplanViewController.floorplanViewControllerDelegate = self
                    floorplanViewController.floorplan = floorplan

                    floorplanViewControllers.insert(floorplanViewController)
                }
            }

            if floorplanViewControllers.count > 0 {
                if let index = floorplanViewControllers.index(of: selectedFloorplanViewController) {
                    let viewController = floorplanViewControllers[index]
                    setViewControllers([viewController], direction: direction, animated: animated, completion: { complete in
                        self.pageViewController(self, willTransitionTo: [viewController])
                    })
                }
            }
        }
    }

    func seek(_ selectedIndex: Int!) {
        if floorplanViewControllers.count > 0 {
            var direction: UIPageViewControllerNavigationDirection = self.selectedIndex > selectedIndex ? .reverse : .forward
            self.selectedIndex = selectedIndex
            if selectedIndex > floorplanViewControllers.count - 1 {
                self.selectedIndex = 0
                direction = .reverse
            }

            resetViewControllers(direction, animated: true)
        }
    }

    func next() {
        if floorplanViewControllers.count > 0 {
            var direction: UIPageViewControllerNavigationDirection = .forward
            selectedIndex += 1
            if selectedIndex > floorplanViewControllers.count - 1 {
                selectedIndex = 0
                direction = .reverse
            }

            resetViewControllers(direction, animated: true)
        }
    }

    func previous() {
        if floorplanViewControllers.count > 0 {
            var direction: UIPageViewControllerNavigationDirection = .reverse
            selectedIndex -= 1
            if selectedIndex < 0 {
                selectedIndex = floorplanViewControllers.count - 1
                direction = .forward
            }

            resetViewControllers(direction, animated: true)
        }
    }

    // MARK: UIPageViewControllerDelegate

    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        if let toolbar = toolbar {
            dispatch_after_delay(0.0) {
                toolbar.reload()
            }
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let toolbar = toolbar {
            dispatch_after_delay(0.0) {
                toolbar.reload()
            }
        }
    }

    // MARK: FloorplanViewControllerDelegate

    func floorplanForFloorplanViewController(_ viewController: FloorplanViewController) -> Floorplan! {
        if let index = floorplanViewControllers.index(of: viewController) {
            return floorplanViewControllers[index].floorplan
        }
        return nil
    }

    func jobForFloorplanViewController(_ viewController: FloorplanViewController) -> Job! {
        return job
    }

    func modeForFloorplanViewController(_ viewController: FloorplanViewController) -> FloorplanViewController.Mode! {
        return job == nil || !job.isPunchlist ? .setup : .workOrders
    }

    func floorplanImageForFloorplanViewController(_ viewController: FloorplanViewController) -> UIImage! {
//        if let image = floorplanPreviewImageView?.image {
//            return image
//        }
        return nil
    }

    func scaleWasSetForFloorplanViewController(_ viewController: FloorplanViewController) {
        //delegate?.jobFloorplansViewController(self, didSetScaleForFloorplanViewController: viewController)
    }

    func scaleCanBeSetByFloorplanViewController(_ viewController: FloorplanViewController) -> Bool {
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

    func newWorkOrderCanBeCreatedByFloorplanViewController(_ viewController: FloorplanViewController) -> Bool {
        return job == nil ? false : !job.isPunchlist
    }

    func navigationControllerForFloorplanViewController(_ viewController: FloorplanViewController) -> UINavigationController! {
        return navigationController
    }

    func areaSelectorIsAvailableForFloorplanViewController(_ viewController: FloorplanViewController) -> Bool {
        return false
    }

    func floorplanViewControllerCanDropWorkOrderPin(_ viewController: FloorplanViewController) -> Bool {
        return job == nil ? false : job.isPunchlist
    }

    func toolbarForFloorplanViewController(_ viewController: FloorplanViewController) -> FloorplanToolbar! {
        return toolbar
    }

    func hideToolbarForFloorplanViewController(_ viewController: FloorplanViewController) {
        hideToolbar()
    }

    func showToolbarForFloorplanViewController(_ viewController: FloorplanViewController) {
        showToolbar()
    }

    // MARK: FloorplanToolbarDelegate

    func floorplanForFloorplanToolbar(_ toolbar: FloorplanToolbar) -> Floorplan {
        if let floorplan = selectedFloorplan {
            return floorplan
        }
        return Floorplan()
    }

    func floorplanToolbar(_ toolbar: FloorplanToolbar, shouldSetFloorplanSelectorVisibility visible: Bool) {
        view.bringSubview(toFront: self.toolbarViewController.view)

        if let floorplanViewController = selectedFloorplanViewController {
            floorplanViewController.setFloorplanSelectorVisibility(visible)
        }
    }

    func floorplanShouldBeRenderedAtIndexPath(_ indexPath: IndexPath, forFloorplanToolbar floorplanToolbar: FloorplanToolbar) {
        if (indexPath as NSIndexPath).row <= floorplanViewControllers.count - 1 {
            seek((indexPath as NSIndexPath).row)
        }
    }

    func previousFloorplanShouldBeRenderedForFloorplanToolbar(_ toolbar: FloorplanToolbar) {
        previous()
    }

    func nextFloorplanShouldBeRenderedForFloorplanToolbar(_ toolbar: FloorplanToolbar) {
        next()
    }

    func previousFloorplanButtonShouldBeEnabledForFloorplanToolbar(_ toolbar: FloorplanToolbar) -> Bool {
        if floorplanViewControllers.count <= 1 {
            return false
        }
        return selectedIndex > 0
    }

    func nextFloorplanButtonShouldBeEnabledForFloorplanToolbar(_ toolbar: FloorplanToolbar) -> Bool {
        if floorplanViewControllers.count <= 1 {
            return false
        }
        return selectedIndex < floorplanViewControllers.count - 1
    }

    func selectedFloorplanForFloorplanToolbar(_ toolbar: FloorplanToolbar) -> Floorplan! {
        if let floorplan = selectedFloorplan {
            return floorplan
        }
        return nil
    }

    func floorplanToolbar(_ toolbar: FloorplanToolbar, shouldSetNavigatorVisibility visible: Bool) {
        view.bringSubview(toFront: self.toolbarViewController.view)

        if let floorplanViewController = selectedFloorplanViewController {
            floorplanViewController.setNavigatorVisibility(visible)
        }
    }

    func floorplanToolbar(_ toolbar: FloorplanToolbar, shouldSetWorkOrdersVisibility visible: Bool, alpha: CGFloat! = nil) {
        view.bringSubview(toFront: self.toolbarViewController.view)

        if let floorplanViewController = selectedFloorplanViewController {
            floorplanViewController.setWorkOrdersVisibility(visible, alpha: alpha)
        }
    }

    func floorplanToolbar(_ toolbar: FloorplanToolbar, shouldSetScaleVisibility visible: Bool) {
        // no-op
    }

    func scaleCanBeSetByFloorplanToolbar(_ toolbar: FloorplanToolbar) -> Bool {
        return false
    }

    func newWorkOrderItemIsShownByFloorplanToolbar(_ toolbar: FloorplanToolbar) -> Bool {
        return false
    }

    func newWorkOrderCanBeCreatedByFloorplanToolbar(_ toolbar: FloorplanToolbar) -> Bool {
        return false
    }

    func newWorkOrderShouldBeCreatedByFloorplanToolbar(_ toolbar: FloorplanToolbar) {
//        polygonView.alpha = 1.0
//        polygonView.attachGestureRecognizer()
//
//        newWorkOrderPending = true
//
//        overrideNavigationItemForCreatingWorkOrder(false) // FIXME: pass true when polygonView has both line endpoints drawn...
    }

    func floorplanToolbar(_ toolbar: FloorplanToolbar, shouldSetFloorplanOptionsVisibility visible: Bool) {
        // no-op
    }

    func floorplanOptionsItemIsShownByFloorplanToolbar(_ toolbar: FloorplanToolbar) -> Bool {
        return false
    }
    
    func floorplanToolbar(_ toolbar: FloorplanToolbar, shouldPresentAlertController alertController: UIAlertController) {
        navigationController!.presentViewController(alertController, animated: true)
    }

    fileprivate func showToolbar() {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut,
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

    fileprivate func hideToolbar() {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut,
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
        NotificationCenter.default.removeObserver(self)
        print("deinit page view controller")
    }
}
