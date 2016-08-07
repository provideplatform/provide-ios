//
//  PackingSlipTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation
import SWTableViewCell

protocol PackingSlipItemTableViewCellDelegate {
    func segmentForPackingSlipItemTableViewCell(cell: PackingSlipItemTableViewCell) -> PackingSlipViewController.Segment!
    func packingSlipItemTableViewCell(cell: PackingSlipItemTableViewCell, didRejectProduct rejectedProduct: Product)
    func packingSlipItemTableViewCell(cell: PackingSlipItemTableViewCell, shouldAttemptToUnloadProduct product: Product)
    func packingSlipItemTableViewCell(cell: PackingSlipItemTableViewCell, shouldAttemptToUnloadRejectedProduct product: Product)
}

class PackingSlipItemTableViewCell: SWTableViewCell, SWTableViewCellDelegate {

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var mpnLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var skuLabel: UILabel!

    var packingSlipItemTableViewCellDelegate: PackingSlipItemTableViewCellDelegate! {
        didSet {
            setupUtilityButtons()
        }
    }

    var product: Product! {
        didSet {
            if let product = product {
                nameLabel?.text = product.name
                mpnLabel?.text = product.gtin
                priceLabel?.text = product.desc // HACK!!! "\(product.price)"
                skuLabel?.text = product.sku

                if product.rejected {
                    descriptionLabel?.text = "REJECTED"
                    descriptionLabel?.textColor = UIColor.redColor()
                } else {
                    descriptionLabel?.text = ""
                    descriptionLabel?.textColor = UIColor.blackColor()
                }
                
                setupUtilityButtons()
            }
        }
    }

    private var canRejectProduct: Bool {
        return workOrder.canRejectGtin(product.gtin)
    }

    private var canUnloadProduct: Bool {
        return workOrder.canUnloadGtin(product.gtin)
    }

    private var workOrder: WorkOrder! {
        return WorkOrderService.sharedService().inProgressWorkOrder
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        delegate = self
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        product = nil

        nameLabel?.text = ""
        mpnLabel?.text = ""
        priceLabel?.text = ""
        skuLabel?.text = ""
        descriptionLabel?.text = ""
    }

    private func setupUtilityButtons() {
        let leftUtilityButtons = NSMutableArray()
        let rightUtilityButtons = NSMutableArray()

        if let segment = packingSlipItemTableViewCellDelegate?.segmentForPackingSlipItemTableViewCell(self) {
            switch segment {
            case .OnTruck:
                //let i = rightUtilityButtons.count
                rightUtilityButtons.sw_addUtilityButtonWithColor(Color.darkBlueBackground(), title: "Unload")
                //rightUtilityButtons[i].removeConstraints(rightUtilityButtons[i].constraints)
            case .Unloaded:
                //let i = rightUtilityButtons.count
                let redColor = UIColor(red: 1.1, green: 0.231, blue: 0.16, alpha: 1.0)
                rightUtilityButtons.sw_addUtilityButtonWithColor(redColor, title: "Reject")
                //rightUtilityButtons[i].removeConstraints(rightUtilityButtons[i].constraints)
            case .Rejected:
                //let i = rightUtilityButtons.count
                rightUtilityButtons.sw_addUtilityButtonWithColor(Color.darkBlueBackground(), title: "Unload")
                //rightUtilityButtons[i].removeConstraints(rightUtilityButtons[i].constraints)
            }
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
        if let segment = packingSlipItemTableViewCellDelegate?.segmentForPackingSlipItemTableViewCell(self) {
            switch segment {
            case .OnTruck:
                if product.rejected {
                    packingSlipItemTableViewCellDelegate?.packingSlipItemTableViewCell(self, shouldAttemptToUnloadRejectedProduct: product)
                } else {
                    packingSlipItemTableViewCellDelegate?.packingSlipItemTableViewCell(self, shouldAttemptToUnloadProduct: product)
                }

            case .Unloaded:
                packingSlipItemTableViewCellDelegate?.packingSlipItemTableViewCell(self, didRejectProduct: product)
            case .Rejected:
                packingSlipItemTableViewCellDelegate?.packingSlipItemTableViewCell(self, shouldAttemptToUnloadRejectedProduct: product)
            }
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
