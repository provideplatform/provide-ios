//
//  PackingSlipTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

protocol PackingSlipItemTableViewCellDelegate {
    func packingSlipItemTableViewCell(cell: PackingSlipItemTableViewCell, didRejectProduct rejectedProduct: Product)
    func packingSlipItemTableViewCell(cell: PackingSlipItemTableViewCell, shouldAttemptToUnloadProduct product: Product)
}

class PackingSlipItemTableViewCell: SWTableViewCell, SWTableViewCellDelegate {

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var mpnLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var skuLabel: UILabel!

    var packingSlipItemTableViewCellDelegate: PackingSlipItemTableViewCellDelegate!

    var product: Product! {
        didSet {
            nameLabel?.text = product.name
            descriptionLabel?.text = ""
            mpnLabel?.text = product.mpn
            priceLabel?.text = product.desc // HACK!!! "\(product.price)"
            skuLabel?.text = product.sku

            setupUtilityButtons()
        }
    }

    private var workOrder: WorkOrder! {
        return WorkOrderService.sharedService().inProgressWorkOrder
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        delegate = self
    }

    private func setupUtilityButtons() {
        let leftUtilityButtons = NSMutableArray()
        let rightUtilityButtons = NSMutableArray()

        if !workOrder.canUnloadGtin(product.gtin) && workOrder.canRejectGtin(product.gtin) {
            let i = rightUtilityButtons.count
            let redColor = UIColor(red: 1.1, green: 0.231, blue: 0.16, alpha: 1.0)
            rightUtilityButtons.sw_addUtilityButtonWithColor(redColor, title: "Reject")
            rightUtilityButtons[i].removeConstraints(rightUtilityButtons[i].constraints)
        }

        if workOrder.canUnloadGtin(product.gtin) {
            let i = rightUtilityButtons.count
            rightUtilityButtons.sw_addUtilityButtonWithColor(Color.darkBlueBackground(), title: "Unload")
            rightUtilityButtons[i].removeConstraints(rightUtilityButtons[i].constraints)
        }

        setLeftUtilityButtons(leftUtilityButtons as [AnyObject], withButtonWidth: 0.0)
        setRightUtilityButtons(rightUtilityButtons as [AnyObject], withButtonWidth: 90.0)
    }

    // MARK: SWTableViewCellDelegate

    func swipeableTableViewCell(cell: SWTableViewCell, canSwipeToState state: SWCellState) -> Bool {
        return true
    }

    func swipeableTableViewCell(cell: SWTableViewCell, didTriggerLeftUtilityButtonWithIndex index: Int) {

    }

    func swipeableTableViewCell(cell: SWTableViewCell, didTriggerRightUtilityButtonWithIndex index: Int) {
        switch index {
        case 0:
            if !workOrder.canUnloadGtin(product.gtin) && workOrder.canRejectGtin(product.gtin) {
                packingSlipItemTableViewCellDelegate?.packingSlipItemTableViewCell(self, didRejectProduct: product)
            } else {
                packingSlipItemTableViewCellDelegate?.packingSlipItemTableViewCell(self, shouldAttemptToUnloadProduct: product)
            }
        case 1:
            packingSlipItemTableViewCellDelegate?.packingSlipItemTableViewCell(self, shouldAttemptToUnloadProduct: product)
        default:
            break
        }
    }

    func swipeableTableViewCell(cell: SWTableViewCell, scrollingToState state: SWCellState) {

    }

    func swipeableTableViewCellDidEndScrolling(cell: SWTableViewCell) {

    }

    func swipeableTableViewCellShouldHideUtilityButtonsOnSwipe(cell: SWTableViewCell) -> Bool {
        return true
    }
}
