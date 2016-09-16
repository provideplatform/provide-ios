//
//  PackingSlipTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import SWTableViewCell

protocol PackingSlipItemTableViewCellDelegate {
    func segmentForPackingSlipItemTableViewCell(_ cell: PackingSlipItemTableViewCell) -> PackingSlipViewController.Segment!
    func packingSlipItemTableViewCell(_ cell: PackingSlipItemTableViewCell, didRejectProduct rejectedProduct: Product)
    func packingSlipItemTableViewCell(_ cell: PackingSlipItemTableViewCell, shouldAttemptToUnloadProduct product: Product)
    func packingSlipItemTableViewCell(_ cell: PackingSlipItemTableViewCell, shouldAttemptToUnloadRejectedProduct product: Product)
}

class PackingSlipItemTableViewCell: SWTableViewCell, SWTableViewCellDelegate {

    @IBOutlet fileprivate weak var nameLabel: UILabel!
    @IBOutlet fileprivate weak var descriptionLabel: UILabel!
    @IBOutlet fileprivate weak var mpnLabel: UILabel!
    @IBOutlet fileprivate weak var priceLabel: UILabel!
    @IBOutlet fileprivate weak var skuLabel: UILabel!

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
                    descriptionLabel?.textColor = UIColor.red
                } else {
                    descriptionLabel?.text = ""
                    descriptionLabel?.textColor = UIColor.black
                }
                
                setupUtilityButtons()
            }
        }
    }

    fileprivate var canRejectProduct: Bool {
        return workOrder.canRejectGtin(product.gtin)
    }

    fileprivate var canUnloadProduct: Bool {
        return workOrder.canUnloadGtin(product.gtin)
    }

    fileprivate var workOrder: WorkOrder! {
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

    fileprivate func setupUtilityButtons() {
        let leftUtilityButtons = NSMutableArray()
        let rightUtilityButtons = NSMutableArray()

        if let segment = packingSlipItemTableViewCellDelegate?.segmentForPackingSlipItemTableViewCell(self) {
            switch segment {
            case .onTruck:
                //let i = rightUtilityButtons.count
                rightUtilityButtons.sw_addUtilityButton(with: Color.darkBlueBackground(), title: "Unload")
                //rightUtilityButtons[i].removeConstraints(rightUtilityButtons[i].constraints)
            case .unloaded:
                //let i = rightUtilityButtons.count
                let redColor = UIColor(red: 1.1, green: 0.231, blue: 0.16, alpha: 1.0)
                rightUtilityButtons.sw_addUtilityButton(with: redColor, title: "Reject")
                //rightUtilityButtons[i].removeConstraints(rightUtilityButtons[i].constraints)
            case .rejected:
                //let i = rightUtilityButtons.count
                rightUtilityButtons.sw_addUtilityButton(with: Color.darkBlueBackground(), title: "Unload")
                //rightUtilityButtons[i].removeConstraints(rightUtilityButtons[i].constraints)
            }
        }

        setLeftUtilityButtons(leftUtilityButtons as [AnyObject], withButtonWidth: 0.0)
        setRightUtilityButtons(rightUtilityButtons as [AnyObject], withButtonWidth: 90.0)
    }

    // MARK: SWTableViewCellDelegate

    func swipeableTableViewCell(_ cell: SWTableViewCell, canSwipeTo state: SWCellState) -> Bool {
        return true
    }

    func swipeableTableViewCell(_ cell: SWTableViewCell, didTriggerLeftUtilityButtonWith index: Int) {

    }

    func swipeableTableViewCell(_ cell: SWTableViewCell, didTriggerRightUtilityButtonWith index: Int) {
        if let segment = packingSlipItemTableViewCellDelegate?.segmentForPackingSlipItemTableViewCell(self) {
            switch segment {
            case .onTruck:
                if product.rejected {
                    packingSlipItemTableViewCellDelegate?.packingSlipItemTableViewCell(self, shouldAttemptToUnloadRejectedProduct: product)
                } else {
                    packingSlipItemTableViewCellDelegate?.packingSlipItemTableViewCell(self, shouldAttemptToUnloadProduct: product)
                }

            case .unloaded:
                packingSlipItemTableViewCellDelegate?.packingSlipItemTableViewCell(self, didRejectProduct: product)
            case .rejected:
                packingSlipItemTableViewCellDelegate?.packingSlipItemTableViewCell(self, shouldAttemptToUnloadRejectedProduct: product)
            }
        }
    }

    func swipeableTableViewCell(_ cell: SWTableViewCell, scrollingTo state: SWCellState) {

    }

    func swipeableTableViewCellDidEndScrolling(_ cell: SWTableViewCell) {

    }

    func swipeableTableViewCellShouldHideUtilityButtons(onSwipe cell: SWTableViewCell) -> Bool {
        return true
    }
}
