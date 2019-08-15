//
//  PaymentMethodTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 12/8/17.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import UIKit

class PaymentMethodTableViewCell: UITableViewCell {

    @IBOutlet private weak var creditCardIcon: UIImageView!
    @IBOutlet private weak var creditCardLastFourLabel: UILabel!
    @IBOutlet private weak var creditCardNoticeLabel: UILabel!

    @IBOutlet private weak var removeButton: UIButton!

    weak private(set) var paymentMethod: PaymentMethod!

    func configure(paymentMethod: PaymentMethod) {
        creditCardIcon.image = paymentMethod.icon
        creditCardLastFourLabel.text = "•••• \(paymentMethod.last4!.suffix(4))"

        if paymentMethod.expired {
            creditCardLastFourLabel.frame.origin.y -= 4.0

            creditCardNoticeLabel.text = "Card expired."
            creditCardNoticeLabel.isHidden = false
        }

        self.paymentMethod = paymentMethod
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        creditCardIcon.image = nil
        creditCardLastFourLabel.text = ""
        creditCardNoticeLabel.text = ""
        creditCardNoticeLabel.isHidden = true
        creditCardLastFourLabel.frame.origin.y -= 22.0

        paymentMethod = nil
    }

    @IBAction private func removePaymentMethod(_ sender: UIButton) {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .alert : .actionSheet
        let alertController = UIAlertController(title: "Confirmation", message: "Remove \(paymentMethod.brand!) ending in \(paymentMethod.last4!)?", preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "No, keep it saved for later", style: .default, handler: nil)
        alertController.addAction(cancelAction)

        let removePaymentMethodAction = UIAlertAction(title: "Remove", style: .destructive) { [weak self] action in
            if let strongSelf = self {
                KTNotificationCenter.post(name: .PaymentMethodShouldBeRemoved, object: strongSelf)
            }
        }

        alertController.addAction(cancelAction)
        alertController.addAction(removePaymentMethodAction)

        alertController.show()
    }
}
