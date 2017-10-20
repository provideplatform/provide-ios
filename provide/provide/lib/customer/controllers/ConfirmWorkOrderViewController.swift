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
    @IBOutlet private weak var creditCardLastFourLabel: UILabel!
    @IBOutlet private weak var capacityLabel: UILabel!
    @IBOutlet private weak var distanceEstimateLabel: UILabel!
    @IBOutlet private weak var fareEstimateLabel: UILabel!
    @IBOutlet private weak var userIconImageView: UIImageView! {
        didSet {
            userIconImageView?.image = userIconImageView?.image?.withRenderingMode(.alwaysTemplate)
            userIconImageView?.tintColor = .lightGray
        }
    }

    @IBAction func categoryChanged(_ sender: CategorySelectionControl) {
        let categoryId = sender.selectedIndex + 1 // TODO: Make robust
        let price = workOrder.estimatedPriceForCategory(categoryId) ?? 0
        fareEstimateLabel.text = "$\(price)"
        workOrder.categoryId = categoryId
    }

    private(set) var workOrder: WorkOrder! {
        didSet {
            if workOrder == nil {
                if oldValue != nil {
                    (parent as? ConsumerViewController)?.animateConfirmWorkOrderView(toHidden: true)
                    self.activityIndicatorView.stopAnimating()
                    self.setViews(hidden: false)
                }
            } else {
                if workOrder.status == "awaiting_schedule" {
                    distanceEstimateLabel.text = "\(workOrder.estimatedDistance) miles / \(workOrder.estimatedDuration) minutes"
                    distanceEstimateLabel.isHidden = false

                    let price = workOrder.estimatedPriceForCategory(1) ?? 0
                    fareEstimateLabel.text = "$\(price)"
                    fareEstimateLabel.isHidden = false

                    // self.creditCardLastFour.text = "" // TODO
                    // self.capacity.text = "" // TODO
                } else if workOrder.status == "pending_acceptance" {
                    setViews(hidden: true)
                    activityIndicatorView.startAnimating()
                }

                if oldValue == nil {
                    (parent as? ConsumerViewController)?.animateConfirmWorkOrderView(toHidden: false)
                }
            }
        }
    }

    private func setViews(hidden: Bool) {
        let views: [UIView] = [
            confirmButton,
            creditCardIcon,
            creditCardLastFourLabel,
            userIconImageView,
            capacityLabel,
            distanceEstimateLabel,
            fareEstimateLabel,
        ]
        views.forEach { $0.isHidden = hidden }
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
