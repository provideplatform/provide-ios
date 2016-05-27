//
//  FloorplanWorkOrderTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 4/11/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class FloorplanWorkOrderTableViewCell: UITableViewCell {

    weak var annotation: Annotation! {
        didSet {
            if NSThread.isMainThread() {
                self.refresh()
            } else {
                dispatch_after_delay(0.0) {
                    self.refresh()
                }
            }
        }
    }

    weak var workOrder: WorkOrder! {
        if let annotation = annotation {
            return annotation.workOrder
        }
        return nil
    }

    @IBOutlet private weak var pinView: FloorplanPinView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var dueDateLabel: UILabel!
    @IBOutlet private weak var priorityLabel: UILabel!

    override func prepareForReuse() {
        super.prepareForReuse()

        pinView.annotation = nil
        pinView.category = nil
        pinView.alpha = 0.0

        titleLabel.text = ""
        dueDateLabel.text = ""
        priorityLabel.text = ""
    }

    private func refresh() {
        pinView?.image = pinView?.image?.imageWithRenderingMode(.AlwaysTemplate)

        if let annotation = annotation {
            pinView.annotation = annotation
            pinView.alpha = 1.0

            if let workOrder = annotation.workOrder {
                if let description = workOrder.desc {
                    titleLabel.text = description
                } else {
                    titleLabel.text = "\(workOrder.category.name)"
                }

                if let humanReadableDueAtTimestamp = workOrder.humanReadableDueAtTimestamp {
                    dueDateLabel.text = "Due \(humanReadableDueAtTimestamp)"
                } else if let humanReadableScheduledStartAtTimestamp = workOrder.humanReadableScheduledStartAtTimestamp {
                    dueDateLabel.text = "Starts \(humanReadableScheduledStartAtTimestamp)"
                }

                if workOrder.priority > 0 {
                    var priorityIndicatorString = ""
                    var i = 0
                    while i < workOrder.priority {
                        priorityIndicatorString = "\(priorityIndicatorString)!"
                        i += 1
                    }
                    priorityLabel.text = priorityIndicatorString
                    priorityLabel.hidden = false
                } else {
                    priorityLabel.text = ""
                    priorityLabel.hidden = true
                }
            } else {
                prepareForReuse()
            }
        } else {
            prepareForReuse()
        }
    }
}