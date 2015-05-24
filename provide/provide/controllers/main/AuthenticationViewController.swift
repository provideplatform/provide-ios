//
//  AuthenticationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class AuthenticationViewController: ViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    private var emailField: UITextField!
    private var passwordField: UITextField!

    @IBOutlet private weak var tableView: UITableView!

    // MARK: UIViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.layer.cornerRadius = 5.0
    }

    func setupNavigationItem() {
        if let navigationController = navigationController {
            navigationController.navigationBarHidden = false
        }

        navigationItem.title = "SIGN IN"
        navigationItem.hidesBackButton = true

        var cancelItem = UIBarButtonItem(title: "CANCEL", style: .Plain, target: self, action: "cancel")
        cancelItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)

        navigationItem.leftBarButtonItems = [cancelItem]
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        updateStatus("")
        showForm()
    }

    // MARK: User Interface Methods

    func cancel() {
        UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseIn,
            animations: {
                if self.emailField?.isFirstResponder() == true {
                    self.emailField?.resignFirstResponder()
                }

                if self.passwordField?.isFirstResponder() == true {
                    self.passwordField?.resignFirstResponder()
                }

                return
            },
            completion: { complete in
                self.performSegueWithIdentifier("AuthenticationViewControllerUnwindSegue", sender: self)
            }
        )
    }

    private func showForm() {
        passwordField?.text = ""

        if emailField?.text?.length > 0 {
            passwordField?.becomeFirstResponder()
        } else {
            emailField?.becomeFirstResponder()
        }

        UIView.animateWithDuration(0.15) {
            self.tableView.alpha = 1
        }
    }

    private func hideForm() {
        view.endEditing(true)

        UIView.animateWithDuration(0.15) {
            self.tableView.alpha = 0
        }
    }

    // MARK: Process Methods

    func submit(sender: UIButton!) {
        let loginInvalid = emailField.text.length == 0 || passwordField.text.length == 0
        if loginInvalid {
            UIAlertView.showToast("Please enter both email and password.")
            return
        }

        hideForm()

        updateStatus("Authenticating")
        login()
    }

    private func login() {
        let params = [
            "email" : emailField.text,
            "password" : passwordField.text]

        ApiService.sharedService().login(params,
            onSuccess: { statusCode, responseString in
                self.userWasAuthenticated()
            },
            onError: { error, statusCode, responseString in
                logError("Failed to create API token")
                self.showError("Authorization failed \(statusCode)")
                self.showForm()
            }
        )
    }

    private func userWasAuthenticated() {
        if let email = KeyChainService.sharedService().email {
            performSegueWithIdentifier("SlidingViewControllerSegue", sender: self)
        }
    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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

    private func emailCell(tableView: UITableView) -> AuthenticationCell {
        let cell = tableView["EmailCell"] as! AuthenticationCell
        emailField = cell.textField
        if let storedEmail = KeyChainService.sharedService().email {
            emailField.text = storedEmail
        }
        if emailField.text.isEmpty && tableView.alpha != 0 {
            emailField.becomeFirstResponder()
        }
        return cell
    }

    private func passwordCell(tableView: UITableView) -> AuthenticationCell {
        let cell = tableView["PasswordCell"] as! AuthenticationCell
        passwordField = cell.textField
        passwordField.text = ""
        passwordField.fixSecureTextFieldFont()
        return cell
    }

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView[indexPath.row] as! AuthenticationCell
        if let textField = cell.textField {
            textField.becomeFirstResponder()
        }
    }

    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if emailField != nil && textField == emailField {
            passwordField.becomeFirstResponder()
            return false
        } else if emailField != nil && emailField.text.isEmpty {
            emailField.becomeFirstResponder()
            return false
        } else {
            submit(nil)
            return true
        }
    }

    func textFieldDidEndEditing(textField: UITextField) {
        if validFieldValues() == false {
            // no-op for now
        }
    }

    // MARK: Validation Methods

    private func validFieldValues() -> Bool {
        return emailField != nil && emailField.text.isValidForEmail()
    }

    // MARK: Navigation Methods

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case "SlidingViewControllerSegue":
            let slidingViewController = segue.destinationViewController as! SlidingViewController
        case "AuthenticationViewControllerUnwindSegue":
            if emailField.isFirstResponder() == true {
                emailField?.resignFirstResponder()
            }

            if passwordField.isFirstResponder() == true {
                passwordField?.resignFirstResponder()
            }

            break
        default:
            assertUnhandledSegue(segue.identifier)
        }
    }

}

class AuthenticationCell: UITableViewCell {
    @IBOutlet private weak var textField: UITextField!
}
