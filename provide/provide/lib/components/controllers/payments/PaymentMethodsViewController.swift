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

    override func viewDidLoad() {
        super.viewDidLoad()

        KTNotificationCenter.addObserver(forName: .PaymentMethodShouldBeRemoved, queue: .main) { [weak self] notification in
            if let sender = notification.object as? PaymentMethodTableViewCell {
                self?.removePaymentMethod(sender: sender)
            }
        }

        reload()
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
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentUser.paymentMethods?.count ?? 0
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(PaymentMethodTableViewCell.self, for: indexPath)
        cell.configure(paymentMethod: currentUser.paymentMethods[indexPath.row])
        return cell
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
}
