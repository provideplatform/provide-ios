//
//  ConfirmWorkOrderViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/26/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

protocol ConfirmWorkOrderViewControllerDelegate: NSObjectProtocol {
    func confirmWorkOrderViewController(_ viewController: ConfirmWorkOrderViewController, didConfirmWorkOrder workOrder: WorkOrder)
}

class ConfirmWorkOrderViewController: ViewController {

    weak var delegate: ConfirmWorkOrderViewControllerDelegate!

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var confirmButton: UIButton!
    @IBOutlet private weak var creditCardIcon: UIImageView!
    @IBOutlet private weak var creditCardLastFour: UILabel!
    @IBOutlet private weak var capacity: UILabel!
    @IBOutlet private weak var distanceEstimate: UILabel!
    @IBOutlet private weak var fareEstimate: UILabel!
    @IBOutlet private weak var userIconImageView: UIImageView! {
        didSet {
            userIconImageView?.image = userIconImageView?.image?.withRenderingMode(.alwaysTemplate)
            userIconImageView?.tintColor = .lightGray
        }
    }

    private var workOrder: WorkOrder! {
        didSet {
            if workOrder == nil {
                if oldValue != nil {
                    UIView.animate(withDuration: 0.25, animations: {
                        self.view.frame.origin.y += self.view.height
                    }, completion: { completed in
                        if self.workOrder == nil {
                            self.activityIndicatorView.stopAnimating()
                            self.confirmButton.isHidden = false
                            self.creditCardIcon.isHidden = false
                            self.creditCardLastFour.isHidden = false
                            self.userIconImageView.isHidden = false
                            self.capacity.isHidden = false
                            self.distanceEstimate.isHidden = false
                            self.fareEstimate.isHidden = false
                        }
                    })
                }
            } else {
                if workOrder.status == "awaiting_schedule" {
                    var distanceTimeEstimate = ""
                    if let estimatedDistance = workOrder.estimatedDistance {
                        distanceTimeEstimate = "\(estimatedDistance) miles"
                    }
                    if let estimatedDuration = workOrder.estimatedDuration {
                        distanceTimeEstimate = "\(distanceTimeEstimate) / \(estimatedDuration) minutes"
                    }
                    distanceEstimate.text = distanceTimeEstimate
                    distanceEstimate.isHidden = false

                    fareEstimate.text = ""
                    if workOrder.estimatedPrice != -1.0 {
                        fareEstimate.text = "$\(workOrder.estimatedPrice)"
                        fareEstimate.isHidden = false
                    }

                    // self.creditCardLastFour.text = "" // TODO
                    // self.capacity.text = "" // TODO
                } else if workOrder.status == "pending_acceptance" {
                    confirmButton.isHidden = true
                    creditCardIcon.isHidden = true
                    creditCardLastFour.isHidden = true
                    userIconImageView.isHidden = true
                    capacity.isHidden = true
                    distanceEstimate.isHidden = true
                    fareEstimate.isHidden = true
                    activityIndicatorView.startAnimating()
                }

                if oldValue == nil {
                    UIView.animate(withDuration: 0.25, animations: {
                        self.view.frame.origin.y -= self.view.height
                    }, completion: { completed in
                        logInfo("Presented work order for confirmation: \(self.workOrder!)")
                    })
                }
            }
        }
    }

    var inProgressWorkOrder: WorkOrder! {
        return workOrder
    }

    @IBAction private func confirm(_ sender: UIButton) {
        sender.isHidden = true
        creditCardIcon.isHidden = true
        creditCardLastFour.isHidden = true
        userIconImageView.isHidden = true
        capacity.isHidden = true
        distanceEstimate.isHidden = true
        fareEstimate.isHidden = true
        activityIndicatorView.startAnimating()

        logInfo("Waiting for a provider to accept the request")

        // TODO: show progress HUD

        workOrder.status = "pending_acceptance"
        workOrder.save(onSuccess: { [weak self] statusCode, mappingResult in
            if let workOrder = mappingResult?.firstObject as? WorkOrder {
                logInfo("Created work order for hire: \(workOrder)")
                self?.delegate?.confirmWorkOrderViewController(self!, didConfirmWorkOrder: workOrder)
            }
        }, onError: { err, statusCode, responseString in
            logWarn("Failed to create work order for hire (\(statusCode))")
        })
    }

    func prepareForReuse() {
        workOrder = nil
    }

    func setWorkOrder(_ workOrder: WorkOrder) {
        self.workOrder = workOrder
    }

    func confirmWorkOrderWithOrigin(_ origin: Contact, destination: Contact) {
        let latitude = origin.latitude!
        let longitude = origin.longitude!

        logInfo("Creating work order from \(latitude.doubleValue),\(longitude.doubleValue) -> \(destination.desc!)")

        // TODO: show progress HUD

        let pendingWorkOrder = WorkOrder()
        pendingWorkOrder.desc = destination.desc
        if let cfg = destination.data {
            pendingWorkOrder.config = [
                "origin": origin.toDictionary() as AnyObject,
                "destination": cfg as AnyObject,
            ]
        }

        pendingWorkOrder.save(onSuccess: { [weak self] statusCode, mappingResult in
            if let workOrder = mappingResult?.firstObject as? WorkOrder {
                logInfo("Created work order for hire: \(workOrder)")
                WorkOrderService.shared.setWorkOrders([workOrder])
                self?.setWorkOrder(workOrder)
            }
        }, onError: { err, statusCode, responseString in
            logWarn("Failed to create work order for hire (\(statusCode))")
        })
    }
}
