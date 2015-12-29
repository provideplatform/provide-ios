//
//  WorkOrderDetailsHeaderTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 12/28/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class WorkOrderDetailsHeaderTableViewCell: SWTableViewCell, SWTableViewCellDelegate {

    weak var workOrder: WorkOrder! {
        didSet {
            if let _ = workOrder {
                refreshUtilityButtons()
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        backgroundColor = UIColor.clearColor()
        contentView.backgroundColor = UIColor(red: 0.11, green: 0.29, blue: 0.565, alpha: 0.45)

        refreshUtilityButtons()
    }

    private func refreshUtilityButtons() {
        let leftUtilityButtons = NSMutableArray()
        let rightUtilityButtons = NSMutableArray()

        rightUtilityButtons.sw_addUtilityButtonWithColor(Color.completedStatusColor(), title: "Complete")
        rightUtilityButtons.sw_addUtilityButtonWithColor(Color.canceledStatusColor(), title: "Cancel")

        setLeftUtilityButtons(leftUtilityButtons as [AnyObject], withButtonWidth: 0.0)
        setRightUtilityButtons(rightUtilityButtons as [AnyObject], withButtonWidth: 90.0)
    }

    // MARK: SWTableViewCellDelegate

    func swipeableTableViewCell(cell: SWTableViewCell!, canSwipeToState state: SWCellState) -> Bool {
        return true
    }

    func swipeableTableViewCellShouldHideUtilityButtonsOnSwipe(cell: SWTableViewCell!) -> Bool {
        return true
    }

    func swipeableTableViewCellDidEndScrolling(cell: SWTableViewCell!) {
        print("ended scrolling!!!! \(cell)")
    }
}
