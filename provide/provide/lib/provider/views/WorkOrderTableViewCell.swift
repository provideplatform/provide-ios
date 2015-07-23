//
//  WorkOrderTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 7/23/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class WorkOrderTableViewCell: UITableViewCell {

    @IBOutlet private weak var customerLabel: UILabel!
    @IBOutlet private weak var startAtLabel: UILabel!
    @IBOutlet private weak var endAtLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var ratingLabel: UILabel!
    @IBOutlet private weak var inventoryLabel: UILabel!

    var workOrder: WorkOrder! {
        didSet {
            customerLabel.text = workOrder.customer.contact.name
            startAtLabel.text = workOrder.startedAt
            endAtLabel.text = workOrder.endedAt

            if let duration = workOrder.duration {
                durationLabel.text = duration.stringValue
            }

            statusLabel.text = workOrder.status

            if let rating = workOrder.providerRating {
                ratingLabel.text = rating.stringValue
            }

            inventoryLabel.text = "\(workOrder.itemsDelivered.count) / \(workOrder.itemsOrdered.count)"
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        customerLabel.text = ""
        startAtLabel.text = ""
        endAtLabel.text = ""
        durationLabel.text = ""
        statusLabel.text = ""
        ratingLabel.text = ""
        inventoryLabel.text = ""
    }
}
