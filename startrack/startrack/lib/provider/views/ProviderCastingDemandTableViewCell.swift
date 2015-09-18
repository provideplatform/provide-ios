//
//  CastingDemandTableViewCell.swift
//  startrack
//
//  Created by Kyle Thomas on 9/18/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class ProviderCastingDemandTableViewCell: UITableViewCell {

    @IBOutlet private weak var avatarImageView: UIImageView!

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var attributesLabel: UILabel!
    @IBOutlet private weak var roleLabel: UILabel!
    @IBOutlet private weak var rateLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var scheduledStartAtLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!

    @IBOutlet private weak var confirmButton: UIButton!
    @IBOutlet private weak var cancelButton: UIButton!

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    var workOrder: WorkOrder! {
        didSet {
            activityIndicatorView?.stopAnimating()

            addBorder(1.0, color: UIColor.lightGrayColor())
            roundCorners(4.0)

            contentView.backgroundColor = UIColor.clearColor()

            castingDemand = workOrder.castingDemand

            if workOrder.isConfirmed {
                cancelButton.sizeToFit()
                cancelButton.alpha = 1.0
                cancelButton.enabled = true

                statusLabel?.text = "CONFIRMED"
                statusLabel?.alpha = 1.0
            } else {
                confirmButton.sizeToFit()
                confirmButton.alpha = 1.0
                confirmButton.enabled = true

                statusLabel?.text = ""
                statusLabel?.alpha = 0.0
            }
        }
    }

    var castingDemand: CastingDemand! {
        didSet {
            nameLabel?.text = castingDemand.actingRole.productionName

            attributesLabel?.text = ""
            roleLabel?.text = "Role: \(castingDemand.actingRole.name)"
            rateLabel?.text = "Rate: $\(castingDemand.rate) / \(castingDemand.estimatedDuration)"
            locationLabel?.text = "@ \(castingDemand.shooting.location.name)"
            scheduledStartAtLabel?.text = "\(castingDemand.scheduledStartAtDate.dateString) @ \(castingDemand.scheduledStartAtDate.timeString!)"
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        prepareForReuse()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        contentView.backgroundColor = UIColor.clearColor()

        nameLabel?.text = ""
        attributesLabel?.text = ""
        roleLabel?.text = ""
        rateLabel?.text = ""
        locationLabel?.text = ""
        scheduledStartAtLabel?.text = ""
        statusLabel?.text = ""
        statusLabel?.alpha = 0.0

        disableActionButtons()

        activityIndicatorView?.stopAnimating()
    }

    private func disableActionButtons() {
        confirmButton?.alpha = 0.0
        cancelButton?.alpha = 0.0

        confirmButton?.enabled = false
        cancelButton?.enabled = false
    }

    @IBAction func confirm(sender: UIButton) {
        disableActionButtons()
        activityIndicatorView?.startAnimating()

        let workOrderProviderParams = [
            "id": workOrder.workOrderProviders.first!.id,
            "provider_id": workOrder.workOrderProviders.first!.provider.id,
            "confirmed_at": NSDate().utcString
        ]

        let params = [
            "work_order_providers": [workOrderProviderParams],
        ]

        ApiService.sharedService().updateWorkOrderWithId(String(workOrder.id), params: params,
            onSuccess: { statusCode, mappingResult in
                WorkOrderService.sharedService().updateWorkOrder(self.workOrder)

                self.activityIndicatorView?.stopAnimating()

                self.statusLabel?.text = "CONFIRMED"
                self.statusLabel?.alpha = 1.0

                self.cancelButton.alpha = 1.0
                self.cancelButton.enabled = true
            },
            onError: { error, statusCode, responseString in
                self.activityIndicatorView?.stopAnimating()
            }
        )
    }

    @IBAction func cancel(sender: UIButton) {
        disableActionButtons()
        activityIndicatorView?.startAnimating()

        let workOrderProviderParams = [
            "id": workOrder.workOrderProviders.first!.id,
            "provider_id": workOrder.workOrderProviders.first!.provider.id,
            "confirmed_at": NSNull()
        ]

        let params = [
            "work_order_providers": [workOrderProviderParams],
        ]

        ApiService.sharedService().updateWorkOrderWithId(String(workOrder.id), params: params,
            onSuccess: { statusCode, mappingResult in
                WorkOrderService.sharedService().updateWorkOrder(self.workOrder)

                self.activityIndicatorView?.stopAnimating()

                self.statusLabel?.text = ""
                self.statusLabel?.alpha = 0.0

                self.confirmButton.alpha = 1.0
                self.confirmButton.enabled = true
            },
            onError: { error, statusCode, responseString in
                self.activityIndicatorView?.stopAnimating()
            }
        )
    }
}
