//
//  WorkOrderTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 7/23/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class WorkOrderTableViewCell: UITableViewCell {

    @IBOutlet fileprivate weak var customerLabel: UILabel!
    @IBOutlet fileprivate weak var durationLabel: UILabel!
    @IBOutlet fileprivate weak var statusLabel: UILabel!
    @IBOutlet fileprivate weak var inventoryLabel: UILabel!

    fileprivate var timer: Timer!

    var workOrder: WorkOrder! {
        didSet {
            timer?.invalidate()

            if let customer = workOrder.customer {
                customerLabel.text = customer.contact.name
            } else if let user = workOrder.user {
                customerLabel.text = user.name
            }

            statusLabel.text = workOrder.status

            if let duration = workOrder.humanReadableDuration {
                durationLabel.text = duration
                durationLabel.alpha = 1.0
            } else {
                durationLabel.alpha = 0.0
            }

            backgroundView?.backgroundColor = workOrder.statusColor
            backgroundView?.alpha = 0.9

            if workOrder.status == "in_progress" || workOrder.status == "en_route" {
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
                timer.fire()
            } else if workOrder.status == "scheduled" {
                durationLabel.text = workOrder.scheduledStartAtDate.timeString
                durationLabel.alpha = 1.0
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        backgroundView?.backgroundColor = .clear
        backgroundView?.alpha = 0.9

        customerLabel.text = ""
        durationLabel.text = ""
        durationLabel.alpha = 0.0
        statusLabel.text = ""
        inventoryLabel.text = ""

        timer?.invalidate()
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundView = UIView(frame: bounds)

        enableEdgeToEdgeDividers()
    }

    func refresh() {
        durationLabel.text = workOrder.humanReadableDuration

        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn,
            animations: {
                let alpha = self.backgroundView?.alpha == 0.0 ? 0.9 : 0.0
                self.backgroundView?.alpha = CGFloat(alpha)
            }
        )
    }
}
