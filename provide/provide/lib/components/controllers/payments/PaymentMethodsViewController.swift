//
//  PaymentMethodsViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/8/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit
import MBProgressHUD

class PaymentMethodsViewController: ViewController, PaymentMethodScannerViewControllerDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet private weak var tokenBalanceHeaderView: TokenBalanceHeaderView!
    @IBOutlet private weak var paymentMethodsTableView: UITableView!
    @IBOutlet private weak var promoCodeInputContainerView: UIView!
    @IBOutlet private weak var promoCodeInputTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        tokenBalanceHeaderView.isHidden = !currentUser.cryptoOptIn

        promoCodeInputContainerView.isHidden = true
        promoCodeInputContainerView.frame.origin.y += promoCodeInputContainerView.height

        KTNotificationCenter.addObserver(forName: .PaymentMethodShouldBeRemoved, queue: .main) { [weak self] notification in
            if let sender = notification.object as? PaymentMethodTableViewCell {
                self?.removePaymentMethod(sender: sender)
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)

        reload()
    }

    @objc
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            UIView.animate(withDuration: 0.25, animations: { [weak self] in
                if let strongSelf = self {
                    strongSelf.promoCodeInputContainerView.alpha = 0.0
                    strongSelf.promoCodeInputContainerView.frame.origin.y += keyboardSize.height
                }
            }, completion: { [weak self] completed in
                self?.promoCodeInputContainerView.isHidden = true
                self?.promoCodeInputContainerView.alpha = 1.0
                //self?.view.disableTapToDismissKeyboard()
            })
        }
    }

    @objc
    func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            promoCodeInputContainerView.isHidden = false
            UIView.animate(withDuration: 0.25, animations: { [weak self] in
                if let strongSelf = self {
                    strongSelf.promoCodeInputContainerView.frame.origin.y -= keyboardSize.height
                    //strongSelf.view.enableTapToDismissKeyboard()
                }
            })
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
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return (currentUser.paymentMethods?.count ?? 0) + 1
        }
        return 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Payment Methods"
        } else if section == 1 {
            return "Promotions"
        }
        return nil
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if indexPath.section == 0 {
            if indexPath.row < tableView.numberOfRows(inSection: indexPath.section) - 1 {
                cell = tableView.dequeue(PaymentMethodTableViewCell.self, for: indexPath)
                cell.selectionStyle = .none
                (cell as! PaymentMethodTableViewCell).configure(paymentMethod: currentUser.paymentMethods[indexPath.row])
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "CallToActionTableViewCellReuseIdentifier")!
                cell.selectionStyle = .gray
                (cell.contentView.subviews.first as! UILabel).text = "Add Payment Method"
            }
        } else if indexPath.section == 1 {
            cell = tableView.dequeueReusableCell(withIdentifier: "CallToActionTableViewCellReuseIdentifier")!
            cell.selectionStyle = .gray
            (cell.contentView.subviews.first as! UILabel).text = "Enter Promo Code"
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == tableView.numberOfRows(inSection: 0) - 1 {
            performSegue(withIdentifier: "PaymentMethodScannerViewControllerSegue", sender: self)
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                presentPromoCodeInputContainerView()
            }
        }

        tableView.deselectRow(at: indexPath, animated: true)
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
        if let code = promoCodeInputTextField?.text {
            if code.lowercased() == "prvd" {
                logInfo("Enabling crypto opt-in functionality for PRVD token")
                KeyChainService.shared.cryptoOptIn = true
            }
        }
        if promoCodeInputTextField.isFirstResponder {
            promoCodeInputTextField.resignFirstResponder()
        }
    }
}
