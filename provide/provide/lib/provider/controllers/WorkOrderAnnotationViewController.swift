//
//  WorkOrderAnnotationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
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

    weak var workOrdersViewControllerDelegate: WorkOrdersViewControllerDelegate?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let minutesEta = WorkOrderService.shared.nextWorkOrderDrivingEtaMinutes {
            self.minutesEta = minutesEta
        }

        monkey("👨‍✈️ Tap: VIEW REQUEST") {
            self.onConfirmationRequired()
        }
    }

    func render() {
        if let mapView = workOrdersViewControllerDelegate?.mapViewForViewController?(nil) {
            mapView.workOrdersViewControllerDelegate = workOrdersViewControllerDelegate

            workOrdersViewControllerDelegate?.removeMapAnnotationsForWorkOrderViewController?(self)

            mapView.addAnnotation(WorkOrderService.shared.nextWorkOrder.annotation)
        }

        (view as! WorkOrderAnnotationView).attachGestureRecognizers()
    }

    private func unwind() {
        (view as! WorkOrderAnnotationView).removeGestureRecognizers()
        workOrdersViewControllerDelegate?.removeMapAnnotationsForWorkOrderViewController?(self)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "WorkOrderAnnotationViewTouchedUpInsideSegue":
            assert(segue.source is WorkOrderAnnotationViewController)
            assert(segue.destination is WorkOrdersViewController)

            if let delegate = workOrdersViewControllerDelegate {
                delegate.confirmationRequiredForWorkOrderViewController?(self)
                delegate.removeMapAnnotationsForWorkOrderViewController?(self)
            }
        case "WorkOrderAnnotationViewControllerUnwindSegue":
            assert(segue.source is WorkOrderAnnotationViewController)
            assert(segue.destination is WorkOrdersViewController)
            unwind()
        default:
            break
        }
    }

    // MARK: WorkOrdersViewControllerDelegate

    func drivingEtaToNextWorkOrderChanged(_ minutesEta: Int) {
        self.minutesEta = minutesEta
    }
}
