//
//  TokenPurchaseViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/8/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit
import MBProgressHUD

class TokenPurchaseViewController: ViewController, UITextFieldDelegate {

    @IBOutlet private weak var quantityTextField: UITextField!
    @IBOutlet private weak var tokenSymbolLabel: UILabel!
    @IBOutlet private weak var tokenUsdExchangeRateLabel: UILabel!
    @IBOutlet private weak var totalPurchasePriceField: UITextField!
    @IBOutlet private weak var cardIcon: UIImageView!
    @IBOutlet private weak var cardNumberLabel: UILabel!
    @IBOutlet private weak var purchaseButton: UIButton!

    private var exchangeRate: Double = 0.0
    private var tokenSymbol: String!

    private var paymentMethod: PaymentMethod!

    override func viewDidLoad() {
        super.viewDidLoad()

        quantityTextField.isHidden = true
        tokenSymbolLabel.isHidden = true
        tokenUsdExchangeRateLabel.isHidden = true
        totalPurchasePriceField.isHidden = true
        cardNumberLabel.isHidden = true
        cardIcon.image = nil
        cardIcon.isHidden = true
        purchaseButton.isHidden = true

        quantityTextField.addTarget(self, action: #selector(quantityChanged(_:)), for: .editingChanged)
        purchaseButton.addTarget(self, action: #selector(confirmTokenPurchase(_:)), for: .touchUpInside)

        refreshTokenPrice()
    }

    private var tokenQuantity: Double {
        if let quantity = Double(quantityTextField.text!) {
            return quantity
        }
        return 0.0
    }

    private var totalPurchasePrice: Double {
        return exchangeRate * tokenQuantity
    }

    private func refreshTokenPrice() {
        MBProgressHUD.showAdded(to: view, animated: true)

        ApiService.shared.fetchPrices([:], onSuccess: { [weak self] statusCode, result in
            if let prices = result?.firstObject as? Prices {
                if let strongSelf = self {
                    MBProgressHUD.hide(for: strongSelf.view, animated: true)
                    strongSelf.configure(tokenSymbol: "PRVD", exchangeRate: prices.prvdusd)
                }
            }
        }, onError: { [weak self] err, statusCode, responseString in
            if let strongSelf = self {
                MBProgressHUD.hide(for: strongSelf.view, animated: true)
            }
        })
    }

    private func configure(tokenSymbol: String, exchangeRate: Double) {
        self.exchangeRate = exchangeRate
        self.tokenSymbol = tokenSymbol

        quantityTextField.text = ""
        tokenSymbolLabel.text = tokenSymbol
        tokenSymbolLabel.sizeToFit()
        tokenUsdExchangeRateLabel.text = String(format: "@ $%.02f per %@", exchangeRate, tokenSymbol)
        tokenUsdExchangeRateLabel.sizeToFit()
        totalPurchasePriceField.text = String(format: "$%.02f", totalPurchasePrice)

        cardIcon.image = nil
        cardNumberLabel.text = ""

        if let paymentMethod = currentUser.defaultPaymentMethod, let last4 = paymentMethod.last4 {
            cardIcon.image = paymentMethod.icon
            cardNumberLabel.text = "•••• \(last4)"

            self.paymentMethod = paymentMethod
        }

        quantityTextField.isHidden = false
        tokenSymbolLabel.isHidden = false
        tokenUsdExchangeRateLabel.isHidden = false
        totalPurchasePriceField.isHidden = false
        cardNumberLabel.isHidden = false
        cardIcon.isHidden = false

        DispatchQueue.main.async { [weak self] in
            if let strongSelf = self {
                if !strongSelf.quantityTextField.isFirstResponder {
                    strongSelf.quantityTextField.becomeFirstResponder()
                }
            }
        }
    }

    private func updateTotalPurchasePrice() {
        DispatchQueue.main.async { [weak self] in
            if let strongSelf = self {
                strongSelf.totalPurchasePriceField.text = String(format: "$%.02f", strongSelf.totalPurchasePrice)
                strongSelf.purchaseButton.isHidden = strongSelf.totalPurchasePrice == 0.0
            }
        }
    }

    @objc private func quantityChanged(_ sender: UITextField) {
        updateTotalPurchasePrice()
    }

    @objc private func confirmTokenPurchase(_ sender: UIButton) {
        purchaseButton.isEnabled = false
        if quantityTextField.isFirstResponder {
            quantityTextField.resignFirstResponder()
        }

        let preferredStyle: UIAlertControllerStyle = isIPad() ? .alert : .actionSheet
        let alertController = UIAlertController(title: "Confirmation", message: "Purchase \(tokenQuantity) \(tokenSymbol!) for \(String(format: "$%.02f", totalPurchasePrice)) \nusing \(paymentMethod.brand!) ending in \(paymentMethod.last4!)?", preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        alertController.addAction(cancelAction)

        let authorizePaymentAction = UIAlertAction(title: "Purchase \(tokenSymbol!)", style: .default) { [weak self] action in
            if let strongSelf = self {
                if strongSelf.quantityTextField.isFirstResponder {
                    strongSelf.quantityTextField.resignFirstResponder()
                }

                strongSelf.completeTokenPurchase()
            }
        }

        alertController.addAction(cancelAction)
        alertController.addAction(authorizePaymentAction)

        alertController.show()
    }

    private func completeTokenPurchase() {
        MBProgressHUD.showAdded(to: view, animated: true)

        let params = [
            "quantity": tokenQuantity,
            "price": exchangeRate,
        ] as [String: Any]

        ApiService.shared.purchaseTokens(params, onSuccess: { [weak self] statusCode, result in
            if let strongSelf = self {
                MBProgressHUD.hide(for: strongSelf.view, animated: true)
            }
        }, onError: { [weak self] err, statusCode, responseString in
            if let strongSelf = self {
                MBProgressHUD.hide(for: strongSelf.view, animated: true)
                strongSelf.purchaseButton.isEnabled = true
            }
        })
    }

    // MARK: UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        if currentText.length == 0  && string == "0" {
            return false
        }
        return true
    }
}
