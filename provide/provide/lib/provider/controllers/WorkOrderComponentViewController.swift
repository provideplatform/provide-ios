//
//  WorkOrderComponentViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol WorkOrderComponentViewControllerDelegate: NSObjectProtocol {
    func workOrderComponentViewControllerForParentViewController(_ viewController: WorkOrderComponentViewController) -> WorkOrderComponentViewController
    @objc optional func mapViewForWorkOrderViewController(_ viewController: UIViewController) -> MapView
    @objc optional func targetViewForViewController(_ viewController: UIViewController) -> UIView
}

class WorkOrderComponentViewController: ViewController {

    weak var delegate: WorkOrderComponentViewControllerDelegate!
    weak var workOrdersViewControllerDelegate: WorkOrdersViewControllerDelegate!

    private var childViewController: WorkOrderComponentViewController!

    private var suspendedTopViewGestureRecognizers: [UIGestureRecognizer]!

    var targetView: UIView! {
        return delegate?.targetViewForViewController?(self)
    }

    func render() {
        if let mapView = delegate?.mapViewForWorkOrderViewController?(self), mapView.alpha == 0 {
            (mapView as! WorkOrderMapView).workOrdersViewControllerDelegate = workOrdersViewControllerDelegate
            mapView.revealMap()
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

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "WorkOrderComponentViewControllerUnwindSegue":
            assert(segue.source is WorkOrderComponentViewController)
            assert(segue.destination is WorkOrdersViewController)
            unwind()
        default:
            break
        }
    }

    // MARK: - Navigation item

    func clearNavigationItem() {
        if let navigationItem = workOrdersViewControllerDelegate?.navigationControllerNavigationItemForViewController?(self) {
            navigationItem.title = nil
            navigationItem.prompt = nil

            navigationItem.leftBarButtonItems = []
            navigationItem.rightBarButtonItems = []
        }
    }
}
