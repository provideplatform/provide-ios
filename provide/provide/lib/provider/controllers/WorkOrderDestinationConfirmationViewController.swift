//
//  WorkOrderDestinationConfirmationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class WorkOrderDestinationConfirmationViewController: ViewController, WorkOrdersViewControllerDelegate {

    var onConfirmationReceived: VoidBlock! {
        didSet {
            if let confirmButton = confirmStartWorkOrderButton {
                confirmButton.onTouchUpInsideCallback = onConfirmationReceived
            }
        }
    }

    var targetView: UIView! {
        get {
            return workOrdersViewControllerDelegate.targetViewForViewController?(self)
        }
    }

    var workOrdersViewControllerDelegate: WorkOrdersViewControllerDelegate!

    private var minutesEta: Int! {
        didSet {
            if let eta = minutesEta {
                if eta > 0 {
                    arrivalEtaEstimateLabel.text = "ARRIVAL TIME IS APPROXIMATELY \(eta) MIN"
                    arrivalEtaEstimateLabel.alpha = 1
                } else {
                    arrivalEtaEstimateLabel.alpha = 0
                    arrivalEtaEstimateLabel.text = ""
                }
            }
        }
    }

    @IBOutlet private weak var arrivalEtaEstimateLabel: UILabel!
    @IBOutlet private weak var confirmStartWorkOrderButton: RoundedButton!

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        confirmStartWorkOrderButton.titleText = "START WORK ORDER" // FIXME
        confirmStartWorkOrderButton.initialBackgroundColor = confirmStartWorkOrderButton.backgroundColor
        
        minutesEta = WorkOrderService.sharedService().nextWorkOrderDrivingEtaMinutes
    }

    // MARK: Rendering

    func render() {
        let frame = CGRectMake(0.0,
                               targetView.frame.size.height,
                               targetView.frame.size.width,
                               view.frame.size.height)

        view.alpha = 0.0
        view.frame = frame

        view.addDropShadow(CGSizeMake(1.0, 1.0), radius: 2.5, opacity: 1.0)

        targetView.addSubview(view)

        setupNavigationItem()

        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseIn,
            animations: {
                self.view.alpha = 1
                self.view.frame = CGRectMake(frame.origin.x,
                                             frame.origin.y - self.view.frame.size.height,
                                             frame.size.width,
                                             frame.size.height)

            },
            completion: { complete in

            }
        )
    }

    // MARK: Status indicator

    func showProgressIndicator() {
        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseOut,
            animations: {
                self.confirmStartWorkOrderButton.alpha = 0
                self.arrivalEtaEstimateLabel.alpha = 0
            },
            completion: { complete in
                self.showActivity()
            }
        )
    }

    func hideProgressIndicator() {
        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseOut,
            animations: {
                self.confirmStartWorkOrderButton.alpha = 1
                self.arrivalEtaEstimateLabel.alpha = 1
            },
            completion: { complete in
                self.hideActivity()
            }
        )
    }

    // MARK Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case "WorkOrderDestinationConfirmationViewControllerUnwindSegue":
            assert(segue.sourceViewController is WorkOrderDestinationConfirmationViewController)
            assert(segue.destinationViewController is WorkOrdersViewController)
            unwind()
            break
        default:
            break
        }
    }

    func unwind() {
        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseIn,
            animations: {
                self.view.alpha = 0
                self.view.frame = CGRectMake(self.view.frame.origin.x,
                                             self.view.frame.origin.y + self.view.frame.size.height,
                                             self.view.frame.size.width,
                                             self.view.frame.size.height)

            },
            completion: { complete in
                self.view.removeFromSuperview()
                self.clearNavigationItem()
            }
        )
    }

    private func setupNavigationItem() {
        if let navigationItem = workOrdersViewControllerDelegate.navigationControllerNavigationItemForViewController?(self) {
            var cancelItem = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: "cancel")
            cancelItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
            cancelItem.title = "CANCEL"

            navigationItem.title = "CONFIRMATION"
            navigationItem.leftBarButtonItems = [cancelItem]
        }
    }

    private func clearNavigationItem() {
        if let navigationItem = workOrdersViewControllerDelegate.navigationControllerNavigationItemForViewController?(self) {
            navigationItem.title = nil

            navigationItem.leftBarButtonItems = []
            navigationItem.rightBarButtonItems = []
        }
    }

    // MARK: Actions

    func cancel() {
        clearNavigationItem()
        workOrdersViewControllerDelegate.confirmationCanceledForWorkOrderViewController?(self)
    }

    // MARK: WorkOrdersViewControllerDelegate

    func drivingEtaToNextWorkOrderChanged(minutesEta: NSNumber!) {
        self.minutesEta = minutesEta as Int
    }

//    // MARK: Location updates (no longer needed due to the above delegate method but here for reference)
    //    private var listeningToLocationUpdates = false
//    private func registerForLocationUpdates() {
//        LocationService.sharedService().resolveCurrentLocation({ location in
//            self.listeningToLocationUpdates = true
//            self.minutesEta = self.workOrdersViewControllerDelegate.drivingEtaToNextWorkOrderForViewController(self)
//            LocationService.sharedService().background()
//        }, durableKey: "workOrderDestinationConfirmationViewController")
//    }
//
//    private func unregisterForLocationUpdates() {
//        listeningToLocationUpdates = false
//        LocationService.sharedService().removeOnLocationResolvedDurableCallback("workOrderDestinationConfirmationViewController")
//    }

}
