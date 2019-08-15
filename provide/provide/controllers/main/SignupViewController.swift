//
//  SignupViewController.swift
//  provide
//
//  Created by Kyle Thomas on 11/28/17.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import UIKit
import MBProgressHUD

class SignupViewController: ViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    private var nameField: UITextField!
    private var emailField: UITextField!
    private var passwordField: UITextField!

    @IBOutlet private weak var tableView: UITableView!

    // MARK: UIViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.layer.cornerRadius = 5.0
    }

    func setupNavigationItem() {
        navigationController?.isNavigationBarHidden = false

        navigationItem.title = "SIGN UP"
        navigationItem.hidesBackButton = true

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "CANCEL", style: .plain, target: self, action: #selector(cancel(_:)))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        updateStatus("")
        showForm()
    }

    // MARK: User Interface Methods

    @objc private func cancel(_: UIBarButtonItem) {
        UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseIn, animations: {
            if self.nameField?.isFirstResponder == true {
                self.nameField?.resignFirstResponder()
            }

            if self.emailField?.isFirstResponder == true {
                self.emailField?.resignFirstResponder()
            }

            if self.passwordField?.isFirstResponder == true {
                self.passwordField?.resignFirstResponder()
            }

            return
        }, completion: { complete in
            self.performSegue(withIdentifier: "SignupViewControllerUnwindSegue", sender: self)
        })
    }

    private func showForm() {
        passwordField?.text = ""

        if let nameField = nameField, let emailField = emailField {
            if nameField.text!.length > 0 && emailField.text!.length > 0 {
                passwordField?.becomeFirstResponder()
            } else {
                emailField.becomeFirstResponder()
            }
        }

        UIView.animate(withDuration: 0.15, animations: {
            self.tableView.alpha = 1
        })
    }

    private func hideForm() {
        view.endEditing(true)

        UIView.animate(withDuration: 0.15, animations: {
            self.tableView.alpha = 0
        })
    }

    // MARK: Process Methods

    private func submit(_: UIButton?) {
        let nameInvalid = nameField.text?.length == 0
        if nameInvalid {
            showToast("Please enter your name.")
            return
        }

        let credentialsInvalid = emailField.text?.length == 0 || passwordField.text?.length == 0
        if credentialsInvalid {
            showToast("Please enter both email and password.")
            return
        }

        hideForm()

        updateStatus("Creating")
        login()
    }

    private func login() {
        MBProgressHUD.showAdded(to: view, animated: true)

        let params = [
            "name": nameField.text!,
            "email": emailField.text!,
            "password": passwordField.text!,
            "time_zone": TimeZone.current.identifier,
        ]

        ApiService.shared.createUser(params, onSuccess: { statusCode, responseString in
            MBProgressHUD.hide(for: self.view, animated: true)
            self.userWasAuthenticated()
        }, onError: { error, statusCode, responseString in
            MBProgressHUD.hide(for: self.view, animated: true)

            logWarn("Failed to create API token")
            self.showError("Authorization failed \(statusCode)")
            self.showForm()
        })
    }

    private func userWasAuthenticated() {
        KTNotificationCenter.post(name: .ApplicationUserWasAuthenticated)
        dispatch_after_delay(1.0) { [weak self] in
            if let strongSelf = self {
                strongSelf.performSegue(withIdentifier: "SignupViewControllerUnwindSegue", sender: strongSelf)
            }
        }
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: AuthenticationCell!

        switch indexPath.row {
        case 0:
            cell = nameCell(tableView)
        case 1:
            cell = emailCell(tableView)
        case 2:
            cell = passwordCell(tableView)
        default:
            assertionFailure("Misconfigured table view form.")
        }

        cell.textField?.delegate = self
        cell.enableEdgeToEdgeDividers()

        return cell
    }

    // MARK: AuthenticationCell setup methods

    private func nameCell(_ tableView: UITableView) -> AuthenticationCell {
        let cell = tableView["NameCell"] as! AuthenticationCell
        nameField = cell.textField
        if nameField.text!.isEmpty && tableView.alpha != 0 {
            nameField.becomeFirstResponder()
        }
        return cell
    }

    private func emailCell(_ tableView: UITableView) -> AuthenticationCell {
        let cell = tableView["EmailCell"] as! AuthenticationCell
        emailField = cell.textField
        return cell
    }

    private func passwordCell(_ tableView: UITableView) -> AuthenticationCell {
        let cell = tableView["PasswordCell"] as! AuthenticationCell
        passwordField = cell.textField
        passwordField.text = ""
        passwordField.fixSecureTextFieldFont()
        return cell
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView[indexPath.row] as! AuthenticationCell
        cell.textField?.becomeFirstResponder()
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if nameField != nil && textField == nameField {
            emailField.becomeFirstResponder()
            return false
        } else if emailField != nil && textField == emailField {
            passwordField.becomeFirstResponder()
            return false
        } else if emailField != nil && emailField.text!.isEmpty {
            emailField.becomeFirstResponder()
            return false
        } else {
            submit(nil)
            return true
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if !validFieldValues() {
            // no-op for now
        }
    }

    // MARK: Validation Methods

    private func validFieldValues() -> Bool {
        return emailField != nil && emailField.text!.isValidEmail()
    }

    // MARK: Navigation Methods

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "SignupViewControllerUnwindSegue":
            if nameField.isFirstResponder {
                nameField.resignFirstResponder()
            }

            if emailField.isFirstResponder {
                emailField.resignFirstResponder()
            }

            if passwordField.isFirstResponder {
                passwordField.resignFirstResponder()
            }
        default:
            logWarn("Attempted unhandled segue")
        }
    }
}
