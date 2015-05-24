//
//  WorkOrderAnnotationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class WorkOrderAnnotationViewController: ViewController, WorkOrdersViewControllerDelegate {

    var onConfirmationRequired: VoidBlock! {
        didSet {
            (view as! WorkOrderAnnotationView).onConfirmationRequired = onConfirmationRequired
        }
    }

    private var minutesEta: Int! {
        didSet {
            (view as! WorkOrderAnnotationView).minutesEta = minutesEta
        }
    }

    var workOrdersViewControllerDelegate: WorkOrdersViewControllerDelegate!

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if let eta = WorkOrderService.sharedService().nextWorkOrderDrivingEtaMinutes {
            minutesEta = eta
        }
    }

    func render() {
        if let mapView = workOrdersViewControllerDelegate.mapViewForViewController?(nil) {
            mapView.workOrdersViewControllerDelegate = workOrdersViewControllerDelegate
            mapView.addAnnotation(WorkOrderService.sharedService().nextWorkOrder)
        }

        (view as! WorkOrderAnnotationView).attachGestureRecognizers()
    }

    func unwind() {
        (view as! WorkOrderAnnotationView).removeGestureRecognizers()

        if let delegate = workOrdersViewControllerDelegate {
            delegate.shouldRemoveMapAnnotationsForWorkOrderViewController?(self)
        }
    }

    // MARK Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case "WorkOrderAnnotationViewTouchedUpInsideSegue":
            assert(segue.sourceViewController is WorkOrderAnnotationViewController)
            assert(segue.destinationViewController is WorkOrdersViewController)

            if let delegate = workOrdersViewControllerDelegate {
                delegate.confirmationRequiredForWorkOrderViewController?(self)
                delegate.shouldRemoveMapAnnotationsForWorkOrderViewController?(self)
            }
            break
        case "WorkOrderAnnotationViewControllerUnwindSegue":
            assert(segue.sourceViewController is WorkOrderAnnotationViewController)
            assert(segue.destinationViewController is WorkOrdersViewController)
            unwind()
            break
        default:
            break
        }
    }

    // MARK: WorkOrdersViewControllerDelegate

    func drivingEtaToNextWorkOrderChanged(minutesEta: NSNumber!) {
        self.minutesEta = minutesEta as Int
    }

}
