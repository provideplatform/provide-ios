//
//  WorkOrderDestinationConfirmationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

class WorkOrderDestinationConfirmationViewController: ViewController, WorkOrdersViewControllerDelegate {

    var onConfirmationReceived: VoidBlock! {
        didSet {
            if let confirmButton = confirmStartWorkOrderButton {
                confirmButton.onTouchUpInsideCallback = onConfirmationReceived
            }
        }
    }

    var targetView: UIView! {
        return workOrdersViewControllerDelegate.targetViewForViewController?(self)
    }

    var workOrdersViewControllerDelegate: WorkOrdersViewControllerDelegate!

    fileprivate var minutesEta: Int! {
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

    @IBOutlet fileprivate weak var arrivalEtaEstimateLabel: UILabel!
    @IBOutlet fileprivate weak var confirmStartWorkOrderButton: RoundedButton!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let _ = WorkOrderService.sharedService().nextWorkOrder {
            confirmStartWorkOrderButton.setTitle("ACCEPT REQUEST", for: .normal) // FIXME
        } else if let _ = WorkOrderService.sharedService().inProgressWorkOrder {
            confirmStartWorkOrderButton.setTitle("CONFIRM DESTINATION", for: .normal) // FIXME
        }
        confirmStartWorkOrderButton.initialBackgroundColor = confirmStartWorkOrderButton.backgroundColor

        minutesEta = WorkOrderService.sharedService().nextWorkOrderDrivingEtaMinutes
    }

    // MARK: Rendering

    func render() {
        let frame = CGRect(
            x: 0.0,
            y: targetView.frame.height,
            width: targetView.frame.width,
            height: view.frame.height
        )

        view.alpha = 0.0
        view.frame = frame

        view.addDropShadow(CGSize(width: 1.0, height: 1.0), radius: 2.5, opacity: 1.0)

        targetView.addSubview(view)

        setupNavigationItem()

        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseIn,
            animations: {
                self.view.alpha = 1
                self.view.frame = CGRect(
                    x: frame.origin.x,
                    y: frame.origin.y - self.view.frame.height,
                    width: frame.width,
                    height: frame.height
                )
            },
            completion: nil
        )
    }

    // MARK: Status indicator

    func showProgressIndicator() {
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut,
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
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut,
            animations: {
                self.confirmStartWorkOrderButton.alpha = 1
                self.arrivalEtaEstimateLabel.alpha = 1
            },
            completion: { complete in
                self.hideActivity()
            }
        )
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "WorkOrderDestinationConfirmationViewControllerUnwindSegue":
            assert(segue.source is WorkOrderDestinationConfirmationViewController)
            assert(segue.destination is WorkOrdersViewController)
            unwind()
        default:
            break
        }
    }

    func unwind() {
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseIn,
            animations: {
                self.view.alpha = 0
                self.view.frame = CGRect(
                    x: self.view.frame.origin.x,
                    y: self.view.frame.origin.y + self.view.frame.height,
                    width: self.view.frame.width,
                    height: self.view.frame.height
                )
            },
            completion: { complete in
                self.view.removeFromSuperview()
                self.clearNavigationItem()
            }
        )
    }

    fileprivate func setupNavigationItem() {
        if let navigationItem = workOrdersViewControllerDelegate.navigationControllerNavigationItemForViewController?(self) {
            navigationItem.title = "CONFIRMATION"
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel(_:)))
        }
    }

    fileprivate func clearNavigationItem() {
        if let navigationItem = workOrdersViewControllerDelegate.navigationControllerNavigationItemForViewController?(self) {
            navigationItem.title = nil

            navigationItem.leftBarButtonItems = []
            navigationItem.rightBarButtonItems = []
        }

        workOrdersViewControllerDelegate.navigationControllerNavBarButtonItemsShouldBeResetForViewController?(self)
    }

    // MARK: Actions

    @objc fileprivate func cancel(_: UIBarButtonItem) {
        clearNavigationItem()
        workOrdersViewControllerDelegate.confirmationCanceledForWorkOrderViewController?(self)
    }

    // MARK: WorkOrdersViewControllerDelegate

    func drivingEtaToNextWorkOrderChanged(_ minutesEta: NSNumber) {
        self.minutesEta = minutesEta as! Int
    }
}
