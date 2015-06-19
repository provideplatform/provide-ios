//
//  WorkOrderComponentViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol WorkOrderComponentViewControllerDelegate {

    func workOrderComponentViewControllerForParentViewController(viewController: WorkOrderComponentViewController!) -> WorkOrderComponentViewController!
    optional func mapViewForWorkOrderViewController(viewController: ViewController!) -> MapView!
    optional func targetViewForViewController(viewController: ViewController!) -> UIView!

}

class WorkOrderComponentViewController: ViewController {

    var delegate: WorkOrderComponentViewControllerDelegate!
    var workOrdersViewControllerDelegate: WorkOrdersViewControllerDelegate!

    private var childViewController: WorkOrderComponentViewController!

    private var slidingView: UIView! {
        return workOrdersViewControllerDelegate?.slidingViewControllerForViewController?(self)?.topViewController.view
    }

    private var suspendedTopViewGestureRecognizers: [UIGestureRecognizer]!

    var targetView: UIView! {
        return delegate?.targetViewForViewController?(self)
    }

    func render() {
        if let mapView = delegate?.mapViewForWorkOrderViewController?(self) {
            if mapView.alpha == 0 {
                (mapView as! WorkOrderMapView).workOrdersViewControllerDelegate = workOrdersViewControllerDelegate
                mapView.revealMap()
            }
        }

        childViewController = delegate?.workOrderComponentViewControllerForParentViewController(self)

        if let vc = childViewController {
            vc.delegate = delegate
            vc.workOrdersViewControllerDelegate = workOrdersViewControllerDelegate
            vc.render()
        }
    }

    func unwind() {
        if let vc = childViewController {
            vc.unwind()
        }

        view.removeFromSuperview()
    }

    // MARK Gesture recognizers

    func enableSuspendedTopViewGestureRecognizers() {
        if let gestureRecognizers = suspendedTopViewGestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                slidingView.addGestureRecognizer(gestureRecognizer)
            }
        }
    }

    func suspendTopViewGestureRecognizers() {
        suspendedTopViewGestureRecognizers = slidingView.gestureRecognizers as! [UIGestureRecognizer]
        if let gestureRecognizers = suspendedTopViewGestureRecognizers {
            for gestureRecognizer in gestureRecognizers {
                slidingView.removeGestureRecognizer(gestureRecognizer)
            }
        }
    }

    // MARK Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case "WorkOrderComponentViewControllerUnwindSegue":
            assert(segue.sourceViewController is WorkOrderComponentViewController)
            assert(segue.destinationViewController is WorkOrdersViewController)
            unwind()
        default:
            break
        }
    }

    // MARK Navigation item

    func clearNavigationItem() {
        if let navigationItem = workOrdersViewControllerDelegate?.navigationControllerNavigationItemForViewController?(self) {
            navigationItem.title = nil
            navigationItem.prompt = nil

            navigationItem.leftBarButtonItems = []
            navigationItem.rightBarButtonItems = []
        }
    }

}
