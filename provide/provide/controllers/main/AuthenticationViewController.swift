//
//  AuthenticationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import MBProgressHUD

class AuthenticationViewController: ViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, ApplicationViewControllerDelegate {

    private var emailField: UITextField!
    private var passwordField: UITextField!

    @IBOutlet private weak var tableView: UITableView!

    // MARK: UIViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.layer.cornerRadius = 5.0

        NotificationCenter.default.addObserverForName("ApplicationUserWasAuthenticated") { _ in
            self.userWasAuthenticated()
        }
    }

    func setupNavigationItem() {
        if let navigationController = navigationController {
            navigationController.isNavigationBarHidden = false
        }

        navigationItem.title = "SIGN IN"
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
            if self.emailField?.isFirstResponder == true {
                self.emailField?.resignFirstResponder()
            }

            if self.passwordField?.isFirstResponder == true {
                self.passwordField?.resignFirstResponder()
            }

            return
        }, completion: { complete in
            self.performSegue(withIdentifier: "AuthenticationViewControllerUnwindSegue", sender: self)
        })
    }

    private func showForm() {
        passwordField?.text = ""

        if let emailField = emailField {
            if emailField.text!.length > 0 {
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
        let loginInvalid = emailField.text?.length == 0 || passwordField.text?.length == 0
        if loginInvalid {
            showToast("Please enter both email and password.")
            return
        }

        hideForm()

        updateStatus("Authenticating")
        login()
    }

    private func login() {
        MBProgressHUD.showAdded(to: view, animated: true)

        let params = [
            "email": emailField.text!,
            "password": passwordField.text!,
        ]

        ApiService.shared.login(params, onSuccess: { statusCode, responseString in
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
        if KeyChainService.shared.email != nil {
            performSegue(withIdentifier: "ApplicationViewControllerSegue", sender: self)
        }
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: AuthenticationCell!

        switch indexPath.row {
        case 0:
            cell = emailCell(tableView)
        case 1:
            cell = passwordCell(tableView)
        default:
            assertionFailure("Misconfigured table view form.")
        }

        cell.textField?.delegate = self
        cell.enableEdgeToEdgeDividers()

        return cell
    }

    // MARK: AuthenticationCell setup methods

    private func emailCell(_ tableView: UITableView) -> AuthenticationCell {
        let cell = tableView["EmailCell"] as! AuthenticationCell
        emailField = cell.textField
        if let storedEmail = KeyChainService.shared.email {
            emailField.text = storedEmail
        }
        if emailField.text!.isEmpty && tableView.alpha != 0 {
            emailField.becomeFirstResponder()
        }
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
        if let textField = cell.textField {
            textField.becomeFirstResponder()
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if emailField != nil && textField == emailField {
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
        case "ApplicationViewControllerSegue":
            (segue.destination as! ApplicationViewController).applicationViewControllerDelegate = self
        case "AuthenticationViewControllerUnwindSegue":
            if emailField.isFirstResponder {
                emailField?.resignFirstResponder()
            }

            if passwordField.isFirstResponder {
                passwordField?.resignFirstResponder()
            }
        default:
            logInfo("Attempted unhandled segue")
        }
    }

    // MARK: ApplicationViewControllerDelegate

    func dismissApplicationViewController(_ viewController: ApplicationViewController) {
        dismiss(animated: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
