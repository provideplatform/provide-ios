//
//  ConfirmWorkOrderViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/26/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

class ConfirmWorkOrderViewController: ViewController {

    func configure(workOrder: WorkOrder, onWorkOrderConfirmed: @escaping (WorkOrder) -> Void) {
        self.workOrder = workOrder
        self.onWorkOrderConfirmed = onWorkOrderConfirmed
    }

    private var onWorkOrderConfirmed: ((WorkOrder) -> Void)!

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
                            self.setViews(hidden: false)
                        }
                    })
                }
            } else {
                if workOrder.status == "awaiting_schedule" {
                    var distanceTimeEstimate = ""
                    if workOrder.estimatedDistance != 0 {
                        distanceTimeEstimate = "\(workOrder.estimatedDistance) miles"
                    }
                    if workOrder.estimatedDuration != 0 {
                        distanceTimeEstimate = "\(distanceTimeEstimate) / \(workOrder.estimatedDuration) minutes"
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
                    setViews(hidden: true)
                    activityIndicatorView.startAnimating()
                }

                if oldValue == nil {
                    UIView.animate(withDuration: 0.25, animations: {
                        self.view.frame.origin.y -= self.view.height
                    }, completion: { completed in
                        guard let workOrder = self.workOrder else { return }
                        logInfo("Presented work order for confirmation: \(workOrder)")
                    })
                }
            }
        }
    }

    private func setViews(hidden: Bool) {
        let views: [UIView] = [
            confirmButton,
            creditCardIcon,
            creditCardLastFour,
            userIconImageView,
            capacity,
            distanceEstimate,
            fareEstimate,
        ]
        views.forEach { $0.isHidden = hidden }
    }

    var inProgressWorkOrder: WorkOrder! {
        return workOrder
    }

    @IBAction private func confirm(_ sender: UIButton) {
        setViews(hidden: true)
        activityIndicatorView.startAnimating()

        logInfo("Waiting for a provider to accept the request")

        // TODO: show progress HUD

        workOrder.status = "pending_acceptance"
        workOrder.save(onSuccess: { [weak self] statusCode, mappingResult in
            if let workOrder = mappingResult?.firstObject as? WorkOrder {
                logInfo("Created work order for hire: \(workOrder)")
                self?.onWorkOrderConfirmed(workOrder)
            }
        }, onError: { err, statusCode, responseString in
            logWarn("Failed to create work order for hire (\(statusCode))")
        })
    }

    func prepareForReuse() {
        workOrder = nil
    }

    func confirmWorkOrderWithOrigin(_ origin: Contact, destination: Contact) {
        let latitude = origin.latitude
        let longitude = origin.longitude

        logInfo("Creating work order from \(latitude),\(longitude) -> \(destination.desc!)")

        // TODO: show progress HUD

        let pendingWorkOrder = WorkOrder()
        pendingWorkOrder.desc = destination.desc
        if let cfg = destination.data {
            pendingWorkOrder.config = [
                "origin": origin.toDictionary(),
                "destination": cfg,
            ]
        }

        pendingWorkOrder.save(onSuccess: { [weak self] statusCode, mappingResult in
            if let workOrder = mappingResult?.firstObject as? WorkOrder {
                logInfo("Created work order for hire: \(workOrder)")
                WorkOrderService.shared.setWorkOrders([workOrder])
                self?.workOrder = workOrder
            }
        }, onError: { err, statusCode, responseString in
            logWarn("Failed to create work order for hire (\(statusCode))")
        })
    }
}
