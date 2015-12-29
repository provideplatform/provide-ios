//
//  WorkOrderDetailsHeaderTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 12/28/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol WorkOrderDetailsHeaderTableViewCellDelegate {
    func workOrderDetailsHeaderTableViewCell(tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldStartWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewCell(tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldCancelWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewCell(tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldCompleteWorkOrder workOrder: WorkOrder)
}

class WorkOrderDetailsHeaderTableViewCell: SWTableViewCell, SWTableViewCellDelegate {

    var workOrderDetailsHeaderTableViewCellDelegate: WorkOrderDetailsHeaderTableViewCellDelegate!

    weak var workOrder: WorkOrder! {
        didSet {
            if let _ = workOrder {
                refresh()
            }
        }
    }

    private var showsCancelButton: Bool {
        if workOrder == nil {
            return false
        }
        return !showsCompleteButton && workOrder.status != "completed" && workOrder.status != "canceled" && workOrder.status != "abandoned"
    }

    private var showsCompleteButton: Bool {
        if workOrder == nil {
            return false
        }
        return workOrder.status == "in_progress"
    }

    private var showsStartButton: Bool {
        if workOrder == nil {
            return false
        }
        return showsCancelButton
    }

    @IBOutlet private weak var previewImageView: UIImageView!
    @IBOutlet private weak var typeLabel: UILabel!
    @IBOutlet private weak var timestampLabel: UILabel!
    @IBOutlet private weak var estimatedSqFtLabel: UILabel!
    @IBOutlet private weak var estimatedCostLabel: UILabel!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        backgroundColor = UIColor.clearColor()
        contentView.backgroundColor = UIColor(red: 0.11, green: 0.29, blue: 0.565, alpha: 0.45)

        delegate = self

        refreshUtilityButtons()
    }

    private func refresh() {
        refreshUtilityButtons()

        if let workOrder = workOrder {
            previewImageView?.contentMode = .ScaleAspectFit
            previewImageView?.image = nil
            if let previewImage = workOrder.previewImage {
                previewImageView?.image = previewImage.scaledToWidth(previewImageView.frame.width)
            }

            typeLabel?.text = workOrder.desc == nil ? workOrder.customer.name : workOrder.desc
            timestampLabel?.text = workOrder.humanReadableScheduledStartAtTimestamp

            if let humanReadableEstimatedSqFt = workOrder.humanReadableEstimatedSqFt {
                estimatedSqFtLabel?.text = humanReadableEstimatedSqFt
            } else {
                estimatedSqFtLabel?.text = "(sq footage unknown)"
            }

            if let humanReadableEstimatedCost = workOrder.humanReadableEstimatedCost {
                estimatedCostLabel?.text = "\(humanReadableEstimatedCost) (estimate)"
            } else {
                estimatedCostLabel?.text = "(cost estimate unknown)"
            }

            typeLabel.sizeToFit()
            timestampLabel.sizeToFit()
            estimatedSqFtLabel.sizeToFit()
            estimatedCostLabel.sizeToFit()
        }
    }

    private func refreshUtilityButtons() {
        let leftUtilityButtons = NSMutableArray()
        let rightUtilityButtons = NSMutableArray()

        if showsCompleteButton {
            rightUtilityButtons.sw_addUtilityButtonWithColor(Color.completedStatusColor(), title: "Complete")
        }

        if showsStartButton {
            rightUtilityButtons.sw_addUtilityButtonWithColor(Color.inProgressStatusColor(), title: "Start")
        }

        if showsCancelButton {
            rightUtilityButtons.sw_addUtilityButtonWithColor(Color.canceledStatusColor(), title: "Cancel")
        }

        setLeftUtilityButtons(leftUtilityButtons as [AnyObject], withButtonWidth: 0.0)
        setRightUtilityButtons(rightUtilityButtons as [AnyObject], withButtonWidth: 90.0)
    }

    // MARK: SWTableViewCellDelegate

    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerLeftUtilityButtonWithIndex index: Int) {
        //  no-op
    }

    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex index: Int) {
        if index == 0 {
            if showsStartButton {
                workOrderDetailsHeaderTableViewCellDelegate?.workOrderDetailsHeaderTableViewCell(self, shouldStartWorkOrder: workOrder)
            } else if showsCancelButton {
                workOrderDetailsHeaderTableViewCellDelegate?.workOrderDetailsHeaderTableViewCell(self, shouldCancelWorkOrder: workOrder)
            } else if showsCompleteButton {
                workOrderDetailsHeaderTableViewCellDelegate?.workOrderDetailsHeaderTableViewCell(self, shouldCompleteWorkOrder: workOrder)
            }
        } else if index == 1 {
            if showsStartButton && showsCancelButton {
                workOrderDetailsHeaderTableViewCellDelegate?.workOrderDetailsHeaderTableViewCell(self, shouldCancelWorkOrder: workOrder)
            }
        }
    }

    func swipeableTableViewCell(cell: SWTableViewCell!, canSwipeToState state: SWCellState) -> Bool {
        return true
    }

    func swipeableTableViewCellShouldHideUtilityButtonsOnSwipe(cell: SWTableViewCell!) -> Bool {
        return true
    }

    func swipeableTableViewCell(cell: SWTableViewCell!, scrollingToState state: SWCellState) {
        // no-op
    }

    func swipeableTableViewCellDidEndScrolling(cell: SWTableViewCell!) {
        // no-op
    }
}
