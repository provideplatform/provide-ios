//
//  TokenBalanceHeaderView.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/17.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import UIKit

class TokenBalanceHeaderView: UIView {

    @IBOutlet private weak var tokenBalanceLabel: UILabel!
    @IBOutlet private weak var usdBalanceLabel: UILabel!

    @IBOutlet private weak var tokenOptionsContainerView: UIView!
    @IBOutlet private weak var buyButton: UIButton! {
        didSet {
            if buyButton != nil {
                buyButton.addTarget(self, action: #selector(buyTokens), for: .touchUpInside)
                buyButton.isEnabled = currentUser.defaultPaymentMethod != nil
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        prepareForReuse()
    }

    func prepareForReuse() {
        tokenBalanceLabel.text = ""
        usdBalanceLabel.text = "$0.00"
        buyButton.isEnabled = currentUser.defaultPaymentMethod != nil

        tokenOptionsContainerView.isHidden = true
    }

    @objc
    private func buyTokens(_ sender: UIButton) {
        KTNotificationCenter.post(name: .ApplicationShouldPresentTokenPurchaseViewController)
    }
}
