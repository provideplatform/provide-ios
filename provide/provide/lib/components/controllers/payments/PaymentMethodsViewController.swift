//
//  PaymentMethodsViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/8/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit
import MBProgressHUD

class PaymentMethodsViewController: ViewController, PaymentMethodScannerViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    //FIXME @IBOutlet private weak var tokenBalanceHeaderView: TokenBalanceHeaderView!
    @IBOutlet private weak var paymentMethodsTableView: UITableView!
    @IBOutlet private weak var promoCodeInputContainerView: UIView!
    @IBOutlet private weak var promoCodeInputTextField: UITextField!
    @IBOutlet private weak var promoCodeApplyButton: UIButton!

    private var paymentMethodsSectionIndex: Int {
        return currentUser.cryptoOptIn ? 1 : 0
    }

    private var promotionsSectionIndex: Int {
        return paymentMethodsSectionIndex + 1
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        promoCodeInputContainerView.isHidden = true

        KTNotificationCenter.addObserver(forName: .PaymentMethodShouldBeRemoved, queue: .main) { [weak self] notification in
            if let sender = notification.object as? PaymentMethodTableViewCell {
                self?.removePaymentMethod(sender: sender)
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: .UIKeyboardDidHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)

        reload()
    }

    @objc
    func keyboardDidHide(notification: NSNotification) {
        promoCodeInputContainerView.isHidden = true
        promoCodeInputContainerView.alpha = 1.0
        promoCodeInputTextField.text = ""
        promoCodeApplyButton.isEnabled = false
    }

    @objc
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            promoCodeInputContainerView.transform = CGAffineTransform(translationX: 0, y: keyboardSize.height)
            UIView.animate(withDuration: 0.25, animations: { [weak self] in
                if let strongSelf = self {
                    strongSelf.promoCodeInputContainerView.alpha = 0.0
                    strongSelf.promoCodeInputContainerView.transform = .identity
                }
            })
        }
    }

    @objc
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            promoCodeInputContainerView.isHidden = false
            promoCodeInputContainerView.transform = CGAffineTransform(translationX: 0, y: -keyboardSize.height)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        switch segue.identifier! {
        case "PaymentMethodScannerViewControllerSegue":
            (segue.destination as! PaymentMethodScannerViewController).delegate = self
        default:
            break
        }
    }

    private func reload() {
        MBProgressHUD.showAdded(to: view, animated: true)

        refreshPaymentMethods()
        refreshToken()
    }

    private func refreshPaymentMethods() {
        currentUser.reloadPaymentMethods(onSuccess: { [weak self] statusCode, result in
            if let strongSelf = self {
                strongSelf.paymentMethodsTableView.reloadData()
                MBProgressHUD.hide(for: strongSelf.view, animated: true)
            }
        }, onError: { [weak self] err, statusCode, responseString in
            if let strongSelf = self {
                logWarn("Failed to refresh payment methods for current user; status code: \(statusCode)")
                MBProgressHUD.hide(for: strongSelf.view, animated: true)
            }
        })
    }

    private func refreshToken() {
        logWarn("refresh token... TODO")

        MBProgressHUD.hide(for: view, animated: true)
    }

    // MARK: PaymentMethodScannerViewControllerDelegate

    func paymentMethodScannerViewController(_ viewController: PaymentMethodScannerViewController, didScanPaymentMethod paymentMethod: PaymentMethod) {
        currentUser.paymentMethods.insert(paymentMethod, at: 0)
        paymentMethodsTableView.reloadData()

        navigationController?.popViewController(animated: false)
    }

    func paymentMethodScannerViewControllerCanceled(_ viewController: PaymentMethodScannerViewController) {
        navigationController?.popViewController(animated: false)
    }

    // MARK: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return currentUser.cryptoOptIn ? 3 : 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == paymentMethodsSectionIndex {
            return (currentUser.paymentMethods?.count ?? 0) + 1
        }
        return 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == paymentMethodsSectionIndex {
            return "Payment Methods"
        } else if section == promotionsSectionIndex {
            return "Promotions"
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && currentUser.cryptoOptIn {
            return 0.0
        }
        return 18.0
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 40.0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && currentUser.cryptoOptIn {
            return 70.0
        }
        return 60.0
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if indexPath.section == 0 && currentUser.cryptoOptIn {
            cell = tableView.dequeueReusableCell(withIdentifier: "TokenBalanceTableViewCellReuseIdentifier")!
            // fixme
        } else if indexPath.section == paymentMethodsSectionIndex {
            if indexPath.row < tableView.numberOfRows(inSection: indexPath.section) - 1 {
                cell = tableView.dequeue(PaymentMethodTableViewCell.self, for: indexPath)
                cell.selectionStyle = .none
                (cell as! PaymentMethodTableViewCell).configure(paymentMethod: currentUser.paymentMethods[indexPath.row])
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "CallToActionTableViewCellReuseIdentifier")!
                cell.selectionStyle = .gray
                (cell.contentView.subviews.first as! UILabel).text = "Add Payment Method"
            }
        } else if indexPath.section == promotionsSectionIndex {
            cell = tableView.dequeueReusableCell(withIdentifier: "CallToActionTableViewCellReuseIdentifier")!
            cell.selectionStyle = .gray
            (cell.contentView.subviews.first as! UILabel).text = "Enter Promo Code"
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == paymentMethodsSectionIndex && indexPath.row == tableView.numberOfRows(inSection: paymentMethodsSectionIndex) - 1 {
            performSegue(withIdentifier: "PaymentMethodScannerViewControllerSegue", sender: self)
        } else if indexPath.section == promotionsSectionIndex {
            if indexPath.row == 0 {
                presentPromoCodeInputContainerView()
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: string)
        promoCodeApplyButton.isEnabled = updatedText.length > 0
        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        promoCodeApplyButton.isEnabled = false
        return true
    }

    private func presentPromoCodeInputContainerView() {
        DispatchQueue.main.async { [weak self] in
            if let strongSelf = self {
                if !strongSelf.promoCodeInputTextField.isFirstResponder {
                    strongSelf.promoCodeInputTextField.becomeFirstResponder()
                }
            }
        }
    }

    @IBAction private func removePaymentMethod(sender: PaymentMethodTableViewCell) {
        if let paymentMethod = sender.paymentMethod {
            MBProgressHUD.showAdded(to: view, animated: true)

            let indexPath = paymentMethodsTableView.indexPath(for: sender)!
            currentUser.paymentMethods.remove(at: indexPath.row)
            paymentMethodsTableView.deleteRows(at: [indexPath], with: .left)

            ApiService.shared.removePaymentMethod(paymentMethod.id, onSuccess: { [weak self] statusCode, result in
                if let strongSelf = self {
                    MBProgressHUD.hide(for: strongSelf.view, animated: true)

                }
            }, onError: { [weak self] err, statusCode, responseText in
                logWarn("Failed to remove payment method; \(statusCode) response")

                if let strongSelf = self {
                    MBProgressHUD.hide(for: strongSelf.view, animated: true)
                }
            })
        }
    }

    @IBAction private func cancelPromoCodeInput(sender: UIButton) {
        if promoCodeInputTextField.isFirstResponder {
            promoCodeInputTextField.resignFirstResponder()
        }
    }

    @IBAction private func applyPromoCodeInput(sender: UIButton) {
        DispatchQueue.main.async { [weak self] in
            if let strongSelf = self {
                if strongSelf.promoCodeInputTextField.isFirstResponder {
                    strongSelf.promoCodeInputTextField.resignFirstResponder()
                }
            }
        }

        if let code = promoCodeInputTextField?.text {
            if code.lowercased() == "prvd" {
                logInfo("Enabling crypto opt-in functionality for PRVD token")

                DispatchQueue.main.async { [weak self] in
                    KeyChainService.shared.cryptoOptIn = true
                    self?.paymentMethodsTableView.reloadData()
                }
            }
        }
    }
}
