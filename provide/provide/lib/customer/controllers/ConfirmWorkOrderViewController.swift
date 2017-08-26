//
//  ConfirmWorkOrderViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/26/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import KTSwiftExtensions

class ConfirmWorkOrderViewController: ViewController {

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var confirmButton: UIButton!
    @IBOutlet private weak var creditCardIcon: UIImageView!
    @IBOutlet private weak var creditCardLastFour: UILabel!
    @IBOutlet private weak var capacity: UILabel!
    @IBOutlet private weak var userIconImageView: UIImageView! {
        didSet {
            if let _ = userIconImageView {
                userIconImageView.image = userIconImageView.image!.withRenderingMode(.alwaysTemplate)
                userIconImageView.tintColor = .lightGray
            }
        }
    }

    fileprivate var workOrder: WorkOrder! {
        didSet {
            if workOrder == nil {
                UIView.animate(
                    withDuration: 0.25,
                    animations: { [weak self] in
                        self!.view.frame.origin.y += self!.view.frame.height
                    },
                    completion: { [weak self] completed in
                        self!.activityIndicatorView.stopAnimating()
                        self!.confirmButton.isHidden = false
                        self!.creditCardIcon.isHidden = false
                        self!.creditCardLastFour.isHidden = false
                        self!.userIconImageView.isHidden = false
                        self!.capacity.isHidden = false
                    }
                )
            } else {
                UIView.animate(
                    withDuration: 0.25,
                    animations: { [weak self] in
                        self!.view.frame.origin.y -= self!.view.frame.height
                    },
                    completion: { _ in
                        
                    }
                )
            }
        }
    }

    @IBAction fileprivate func confirm(_ sender: UIButton) {
        sender.isHidden = true
        creditCardIcon.isHidden = true
        creditCardLastFour.isHidden = true
        userIconImageView.isHidden = true
        capacity.isHidden = true
        activityIndicatorView.startAnimating()

        logInfo("Waiting for a provider to accept the request")
        logWarn("TODO: submit the work order via work orders API")
    }

    fileprivate func prepareForReuse() {
        workOrder = nil
    }

    func confirmWorkOrderWithOriginCoordinate(_ coordinate: CLLocationCoordinate2D, destination: Contact) {
        let latitude = NSNumber(value: coordinate.latitude)
        let longitude = NSNumber(value: coordinate.longitude)

        logInfo("Creating work order from \(latitude.doubleValue),\(longitude.doubleValue) -> \(destination.desc!)")
        
        let pendingWorkOrder = WorkOrder()
        pendingWorkOrder.status = "awaiting_schedule"
        pendingWorkOrder.customer = Customer() // awaiting_schedule // FIXME
        pendingWorkOrder.destination = destination // FIXME
        pendingWorkOrder.desc = destination.desc
        
        workOrder = pendingWorkOrder
    }
}
