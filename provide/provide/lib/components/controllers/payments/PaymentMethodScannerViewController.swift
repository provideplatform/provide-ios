//
//  PaymentMethodScannerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit
import MBProgressHUD

@objc protocol PaymentMethodScannerViewControllerDelegate: NSObjectProtocol {
    func paymentMethodScannerViewController(_ viewController: PaymentMethodScannerViewController, didScanPaymentMethod paymentMethod: PaymentMethod)
    func paymentMethodScannerViewControllerCanceled(_ viewController: PaymentMethodScannerViewController)
//    func paymentMethodScannerViewControllerFailed(_ viewController: PaymentMethodScannerViewController)
}

@objcMembers
class PaymentMethodScannerViewController: ViewController, CardIOViewDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    weak var delegate: PaymentMethodScannerViewControllerDelegate!

    @IBOutlet private weak var creditCardTableView: UITableView!

    private var cardIOView: CardIOView!

    private var cardIcon: UIImageView!
    private var cardNumberField: UITextField!
    private var expiryMonthField: UITextField!
    private var expiryYearField: UITextField!
    private var cvcField: UITextField!

    private var pending = false
    private var scanAttempts = 0
    private var timer: Timer?

    private var paymentMethod: PaymentMethod! {
        didSet {
            if paymentMethod != nil {
                cardIOView.isHidden = true

                cardIcon.image = paymentMethod.icon
                cardNumberField.text = paymentMethod.last4
                expiryMonthField.text = "\(paymentMethod.expMonth)"
                expiryYearField.text = "\(paymentMethod.expYear)"
                expiryYearField.sizeToFit()

                creditCardTableView?.isHidden = false

                if !cvcField.isFirstResponder {
                    cvcField.becomeFirstResponder()
                }
            } else {
                if cardIOView != nil {
                    cardIOView.isHidden = false
                    cardIOView.removeFromSuperview()
                    cardIOView = nil
                }

                creditCardTableView?.isHidden = true
                creditCardTableView?.reloadData()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        scan()
    }

    private func scan() {
        if cardIOView != nil {
            cardIOView.removeFromSuperview()
            cardIOView = nil
        }

        creditCardTableView.isHidden = true

        cardIOView = CardIOView(frame: view.bounds)
        cardIOView.delegate = self
        cardIOView.hideCardIOLogo = true
        cardIOView.scannedImageDuration = 0.1
        cardIOView.isHidden = true

        view.addSubview(cardIOView)
        view.bringSubview(toFront: cardIOView)
        cardIOView.isHidden = false // TODO-- remove default animation
    }

    @objc private func createPaymentMethod() {
        timer?.invalidate()
        timer = nil

        if pending {
            return
        }

        pending = true
        MBProgressHUD.showAdded(to: view, animated: true)

        ApiService.shared.createPaymentMethod(paymentMethod.toDictionary(), onSuccess: { [weak self] statusCode, result in
            if let strongSelf = self {
                strongSelf.pending = false
                MBProgressHUD.hide(for: strongSelf.view, animated: true)

                strongSelf.delegate?.paymentMethodScannerViewController(strongSelf, didScanPaymentMethod: result?.firstObject as! PaymentMethod)
            }
        }, onError: { [weak self] err, statusCode, responseString in
            logWarn("Failed to create payment method; \(statusCode) response")

            if let strongSelf = self {
                strongSelf.pending = false
                MBProgressHUD.hide(for: strongSelf.view, animated: true)

                var msg = "Invalid credit card details provided"
                if let errs = (err.userInfo["errors"] as? [String: Any])?.values.first as? [String], let errmsg = errs.first {
                    msg = errmsg
                }
                NotificationService.shared.presentStatusBarNotificationWithTitle(msg, style: .danger, autoDismiss: true)

                strongSelf.cvcField.text = ""
                strongSelf.cvcField?.becomeFirstResponder()
            }
        })
    }

    // MARK: CardIOViewDelegate

    func cardIOView(_ cardIOView: CardIOView, didScanCard cardInfo: CardIOCreditCardInfo) {
         cardIOView.isHidden = true
        if let pmtMethod = cardInfo.toPaymentMethod() {
            paymentMethod = pmtMethod
        } else {
            scanAttempts += 1

            let msg = "Hold your camera and credit card steady..."
            NotificationService.shared.presentStatusBarNotificationWithTitle(msg, style: .warning, autoDismiss: true)

            scan()
        }
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!

        switch indexPath.row {
        case 0:
            cell = cardNumberCell(tableView)
        case 1:
            cell = expiryCell(tableView)
        case 2:
            cell = cvcCell(tableView)
        default:
            assertionFailure("Misconfigured table view form.")
        }

        cell.enableEdgeToEdgeDividers()

        return cell
    }

    // MARK: AuthenticationCell setup methods

    private func cardNumberCell(_ tableView: UITableView) -> UITableViewCell {
        let cell = tableView["CardNumberCell"]
        if let imageView = cell.contentView.subviews.first(where: { subv -> Bool in
            return subv.isKind(of: UIImageView.self)
        }) as? UIImageView {
            cardIcon = imageView
            cardIcon.image = nil
        }
        if let textField = cell.contentView.subviews.first(where: { subv -> Bool in
            return subv.isKind(of: UITextField.self)
        }) as? UITextField {
            cardNumberField = textField
            cardNumberField.text = ""
        }
        if cardNumberField.text!.isEmpty && !tableView.isHidden {
            cardNumberField.becomeFirstResponder()
        }
        return cell
    }

    private func expiryCell(_ tableView: UITableView) -> UITableViewCell {
        let cell = tableView["ExpiryCell"]
        if let textField = cell.contentView.subviews.first(where: { subv -> Bool in
            return subv.isKind(of: UITextField.self)
        }) as? UITextField {
            expiryMonthField = textField
            expiryMonthField.text = ""
        }
        if let textField = cell.contentView.subviews.first(where: { subv -> Bool in
            return subv.isKind(of: UITextField.self) && subv != expiryMonthField
        }) as? UITextField {
            expiryYearField = textField
            expiryYearField.text = ""
        }
        return cell
    }

    private func cvcCell(_ tableView: UITableView) -> UITableViewCell {
        let cell = tableView["CVCCell"]
        if let textField = cell.contentView.subviews.first(where: { subv -> Bool in
            return subv.isKind(of: UITextField.self)
        }) as? UITextField {
            cvcField = textField
            cvcField.text = ""
            cvcField.delegate = self
        }
        return cell
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // no-op
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if cardNumberField != nil && textField == cardNumberField {
            expiryMonthField.becomeFirstResponder()
            return false
        } else if expiryMonthField != nil && expiryMonthField.text!.isEmpty {
            expiryMonthField.becomeFirstResponder()
            return false
        } else if expiryYearField != nil && expiryYearField.text!.isEmpty {
            expiryYearField.becomeFirstResponder()
            return false
        } else if cvcField != nil && cvcField.text!.isEmpty {
            cvcField.becomeFirstResponder()
            return false
        } else {
            return true
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        timer?.invalidate()
        timer = nil

        if pending || paymentMethod == nil {
            return false
        }

        let currentText = textField.text ?? ""
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: string)

        if updatedText.count > 4 {
            return false
        } else if updatedText.count == 3 || updatedText.count == 4 { // valid cvc length
            DispatchQueue.main.async { [weak self] in
                if let strongSelf = self {
                    if strongSelf.cvcField.isFirstResponder {
                        strongSelf.cvcField.resignFirstResponder()
                    }

                    strongSelf.paymentMethod.cvc = updatedText
                    strongSelf.timer = Timer.scheduledTimer(timeInterval: 0.25, target: strongSelf, selector: #selector(strongSelf.createPaymentMethod), userInfo: nil, repeats: false)
                }
            }

        }

        return true
    }
}
