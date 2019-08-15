//
//  WorkOrderAnnotationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
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

        monkey("👨‍✈️ Tap: VIEW REQUEST") {
            self.onConfirmationRequired()
        }
    }

    func render() {
        if let minutesEta = WorkOrderService.shared.nextWorkOrderDrivingEtaMinutes {
            self.minutesEta = minutesEta
        }

        if let timeoutAt = WorkOrderService.shared.nextWorkOrder?.nextTimeoutAtDate {
            (view as! WorkOrderAnnotationView).timeoutAt = timeoutAt

            DispatchQueue.main.asyncAfter(deadline: .now() + timeoutAt.timeIntervalSinceNow) { [weak self] in
                if WorkOrderService.shared.nextWorkOrder != nil {
                    logInfo("Preemptively timing out unaccepted work order prior to receiving notification")
                    if let strongSelf = self {
                        strongSelf.workOrdersViewControllerDelegate?.removeMapAnnotationsForWorkOrderViewController?(strongSelf)
                        strongSelf.performSegue(withIdentifier: "WorkOrderAnnotationViewControllerUnwindSegue", sender: nil)
                    }
                }
            }
        }

        if let mapView = workOrderMapView {
            mapView.workOrdersViewControllerDelegate = workOrdersViewControllerDelegate

            if let annotation = WorkOrderService.shared.nextWorkOrder?.annotation {
                if !mapView.annotations.contains(where: { ($0 as? WorkOrder.Annotation)?.matches(annotation.workOrder) == true }) {
                    mapView.addAnnotation(annotation)
                }
            }

            if let workOrder = WorkOrderService.shared.nextWorkOrder {
                mapView.renderOverviewPolylineForWorkOrder(workOrder)
            }

            mapView.mapViewShouldRefreshVisibleMapRect(mapView, animated: true)
        }

        (view as! WorkOrderAnnotationView).attachGestureRecognizers()
    }

    private func unwind() {
        (view as! WorkOrderAnnotationView).prepareForReuse()
        workOrderMapView?.removeAnnotations()
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "WorkOrderAnnotationViewTouchedUpInsideSegue":
            assert(segue.source is WorkOrderAnnotationViewController && segue.destination is WorkOrdersViewController)

            if let delegate = workOrdersViewControllerDelegate {
                workOrderMapView?.removeAnnotations()
                delegate.segueToWorkOrderDestinationConfirmationViewController?(self)
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
