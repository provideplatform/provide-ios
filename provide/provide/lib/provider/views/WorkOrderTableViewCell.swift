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
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var inventoryLabel: UILabel!

    private var timer: NSTimer!

    var workOrder: WorkOrder! {
        didSet {
            customerLabel.text = workOrder.customer.contact.name
            statusLabel.text = workOrder.status
            inventoryLabel.text = workOrder.inventoryDisposition

            if let duration = workOrder.humanReadableDuration {
                durationLabel.text = duration
            }

            backgroundView?.backgroundColor = workOrder.statusColor
            backgroundView?.alpha = 0.9

            if workOrder.status == "in_progress" || workOrder.status == "en_route" {
                timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "refresh", userInfo: nil, repeats: true)
                timer.fire()
            } else if workOrder.status == "scheduled" {
                durationLabel.text = workOrder.scheduledStartAtDate.timeString
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        backgroundView?.backgroundColor = UIColor.clearColor()
        backgroundView?.alpha = 0.9

        customerLabel.text = ""
        durationLabel.text = ""
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

        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseIn,
            animations: {
                let alpha = self.backgroundView?.alpha == 0.0 ? 0.9 : 0.0
                self.backgroundView?.alpha = CGFloat(alpha)
            },
            completion: { complete in

            }
        )
    }
}
