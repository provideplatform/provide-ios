//
//  PaymentMethodTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 12/8/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit

class PaymentMethodTableViewCell: UITableViewCell {

    @IBOutlet private weak var creditCardIcon: UIImageView!
    @IBOutlet private weak var creditCardLastFourLabel: UILabel!
    @IBOutlet private weak var creditCardNoticeLabel: UILabel!

    func configure(paymentMethod: PaymentMethod) {
        creditCardIcon.image = paymentMethod.icon
        creditCardLastFourLabel.text = "•••• \(paymentMethod.last4!.suffix(4))"

        if paymentMethod.expired {
            creditCardLastFourLabel.frame.origin.y -= 4.0

            creditCardNoticeLabel.text = "Card expired."
            creditCardNoticeLabel.isHidden = false
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        creditCardIcon.image = nil
        creditCardLastFourLabel.text = ""
        creditCardNoticeLabel.text = ""
        creditCardNoticeLabel.isHidden = true
        creditCardLastFourLabel.frame.origin.y -= 22.0
    }
}
