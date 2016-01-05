//
//  JobProductTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 12/11/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class JobProductTableViewCell: UITableViewCell {

    @IBOutlet private weak var gtinLabel: UILabel!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var quantityLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!

    @IBOutlet private weak var statusBackgroundView: UIView! {
        didSet {
            if let _ = statusBackgroundView {
                resetStatusBackgroundView()
            }
        }
    }
    
    var jobProduct: JobProduct! {
        didSet {
            if let jobProduct = jobProduct {
                if let name = product.name {
                    nameLabel?.text = name
                }

                if let gtin = product.gtin {
                    gtinLabel?.text = gtin
                }

                quantityLabel?.text = "\(NSString(format: "%.03f", jobProduct.remainingQuantity) as String) remaining"
                quantityLabel?.sizeToFit()

                priceLabel?.text = "" //NSString(format: "$%.02f", jobProduct.price) as String

                renderStatusBackgroundView()
            }
        }
    }

    var product: Product! {
        if let jobProduct = jobProduct {
            return jobProduct.product
        }
        return nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        resetStatusBackgroundView()

        nameLabel?.text = ""
        gtinLabel?.text = ""
        quantityLabel?.text = ""
        priceLabel?.text = ""
    }

    private func resetStatusBackgroundView() {
        statusBackgroundView.roundCorners(5.0)
        statusBackgroundView.alpha = 0.8
        statusBackgroundView.backgroundColor = UIColor.clearColor()
        statusBackgroundView.frame.size = CGSize(width: 0.0, height: statusBackgroundView.frame.height)

        contentView.sendSubviewToBack(statusBackgroundView)
    }

    private func renderStatusBackgroundView() {
        dispatch_after_delay(0.0) {
            self.resetStatusBackgroundView()
            self.statusBackgroundView.backgroundColor = self.jobProduct.statusColor

            UIView.animateWithDuration(0.4, delay: 0.15, options: .CurveEaseInOut,
                animations: {
                    self.statusBackgroundView.frame = CGRect(x: 0.0,
                        y: 0.0,
                        width: CGFloat(self.contentView.bounds.width) * CGFloat(self.jobProduct.percentageRemaining),
                        height: self.contentView.bounds.height)
                },
                completion: { complete in

                }
            )
        }
    }
}
