//
//  TokenBalanceHeaderView.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
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

        tokenOptionsContainerView.isHidden = true
    }

    @objc
    private func buyTokens(_ sender: UIButton) {
        KTNotificationCenter.post(name: .ApplicationShouldPresentTokenPurchaseViewController)
    }
}
