//
//  WorkOrderAnnotationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class WorkOrderAnnotationViewController: ViewController, WorkOrdersViewControllerDelegate {

    private weak var workOrdersViewControllerDelegate: WorkOrdersViewControllerDelegate?
    private weak var workOrderMapView: WorkOrderMapView?

    private var onConfirmationRequired: VoidBlock! {
        didSet {
            (view as! WorkOrderAnnotationView).onConfirmationRequired = onConfirmationRequired
        }
    }

    func configure(delegate: WorkOrdersViewControllerDelegate, mapView: WorkOrderMapView, onConfirmationRequired: @escaping VoidBlock) {
        self.workOrdersViewControllerDelegate = delegate
        self.workOrderMapView = mapView
        self.onConfirmationRequired = onConfirmationRequired
    }

    private var minutesEta: Int! {
        didSet {
            (view as! WorkOrderAnnotationView).minutesEta = minutesEta
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let workOrder = WorkOrderService.shared.nextWorkOrder {
            workOrderMapView?.renderOverviewPolylineForWorkOrder(workOrder)
        }

        if let minutesEta = WorkOrderService.shared.nextWorkOrderDrivingEtaMinutes {
            self.minutesEta = minutesEta
        }

        if let timeoutAt = WorkOrderService.shared.nextWorkOrder?.nextTimeoutAtDate {
            (view as! WorkOrderAnnotationView).timeoutAt = timeoutAt

            DispatchQueue.main.asyncAfter(deadline: .now() + timeoutAt.timeIntervalSinceNow) { [weak self] in
                logInfo("Preemptively timing out unaccepted work order prior to receiving notification")
                self?.performSegue(withIdentifier: "WorkOrderAnnotationViewControllerUnwindSegue", sender: nil)
            }
        }

        monkey("👨‍✈️ Tap: VIEW REQUEST") {
            self.onConfirmationRequired()
        }
    }

    func render() {
        if let mapView = workOrderMapView {
            mapView.workOrdersViewControllerDelegate = workOrdersViewControllerDelegate
            workOrdersViewControllerDelegate?.removeMapAnnotationsForWorkOrderViewController?(self)
            if let annotation = WorkOrderService.shared.nextWorkOrder?.annotation {
                mapView.addAnnotation(annotation)
            }
        }

        (view as! WorkOrderAnnotationView).attachGestureRecognizers()
    }

    private func unwind() {
        (view as! WorkOrderAnnotationView).prepareForReuse()
        workOrdersViewControllerDelegate?.removeMapAnnotationsForWorkOrderViewController?(self)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "WorkOrderAnnotationViewTouchedUpInsideSegue":
            assert(segue.source is WorkOrderAnnotationViewController && segue.destination is WorkOrdersViewController)

            if let delegate = workOrdersViewControllerDelegate {
                delegate.segueToWorkOrderDestinationConfirmationViewController?(self)
                delegate.removeMapAnnotationsForWorkOrderViewController?(self)
            }
        case "WorkOrderAnnotationViewControllerUnwindSegue":
            assert(segue.source is WorkOrderAnnotationViewController && segue.destination is WorkOrdersViewController)
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
