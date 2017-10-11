//
//  SetPasswordViewController.swift
//  provide
//
//  Created by Kyle Thomas on 3/5/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import MBProgressHUD

protocol SetPasswordViewControllerDelegate: class {
    func setPasswordViewController(_ viewController: SetPasswordViewController, didSetPassword success: Bool)
}

class SetPasswordViewController: ViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    weak var delegate: SetPasswordViewControllerDelegate?

    @IBOutlet private weak var tableView: UITableView!

    @IBOutlet private weak var passwordField: UITextField!
    @IBOutlet private weak var confirmField: UITextField!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateStatus("")
        showForm()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "SetPasswordViewControllerUnwindSegue":
            if confirmField.isFirstResponder {
                confirmField?.resignFirstResponder()
            }
        default:
            logInfo("Attempted unhandled segue")
        }
    }

    func setupNavigationItem() {
        if let navigationController = navigationController {
            navigationController.isNavigationBarHidden = false
        }

        navigationItem.title = "SET PASSWORD"
        navigationItem.hidesBackButton = true
    }

    private func submit() {
        let passwordValid = passwordField != nil && confirmField != nil && passwordField.text!.length >= 7 && passwordField.text == confirmField.text
        if !passwordValid {
            showToast("Please enter and confirm your new password.")
            return
        }

        hideForm()

        updateStatus("Changing Password")
        setPassword()
    }

    private func setPassword() {
        MBProgressHUD.showAdded(to: view, animated: true)

        let params = [
            "password": passwordField.text!,
        ]

        ApiService.shared.updateUser(params, onSuccess: { statusCode, responseString in
            MBProgressHUD.hide(for: self.view, animated: true)

            self.performSegue(withIdentifier: "SetPasswordViewControllerUnwindSegue", sender: self)
            self.delegate?.setPasswordViewController(self, didSetPassword: true)
        }, onError: { error, statusCode, responseString in
            MBProgressHUD.hide(for: self.view, animated: true)

            self.showError("Failed to change password \(statusCode)")
            self.showForm()

            self.delegate?.setPasswordViewController(self, didSetPassword: false)
        })
    }

    private func hideForm() {
        view.endEditing(true)

        UIView.animate(withDuration: 0.15, animations: {
            self.tableView.alpha = 0
        })
    }

    private func showForm() {
        passwordField?.text = ""
        confirmField?.text = ""

        passwordField?.becomeFirstResponder()

        UIView.animate(withDuration: 0.15, animations: {
            self.tableView.alpha = 1
        })
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: AuthenticationCell!

        switch indexPath.row {
        case 0:
            cell = passwordCell(tableView)
        case 1:
            cell = confirmCell(tableView)
        default:
            assertionFailure("Misconfigured table view form.")
        }

        cell.textField?.delegate = self
        cell.enableEdgeToEdgeDividers()

        return cell
    }

    private func passwordCell(_ tableView: UITableView) -> AuthenticationCell {
        let cell = tableView["PasswordCell"] as! AuthenticationCell
        passwordField = cell.textField
        passwordField.text = ""
        passwordField.fixSecureTextFieldFont()
        return cell
    }

    private func confirmCell(_ tableView: UITableView) -> AuthenticationCell {
        let cell = tableView["ConfirmCell"] as! AuthenticationCell
        confirmField = cell.textField
        confirmField.text = ""
        confirmField.fixSecureTextFieldFont()
        return cell
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if passwordField != nil && textField == passwordField {
            confirmField.becomeFirstResponder()
            return false
        } else {
            submit()
            return true
        }
    }
}
