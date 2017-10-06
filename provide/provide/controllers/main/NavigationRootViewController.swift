//
//  NavigationRootViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import MBProgressHUD

class NavigationRootViewController: ViewController, ApplicationViewControllerDelegate, SetPasswordViewControllerDelegate, PinInputViewControllerDelegate {

    @IBOutlet fileprivate var logoImageView: UIImageView!
    @IBOutlet fileprivate var signInButton: UIButton!
    @IBOutlet fileprivate var codeButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        logoImageView.alpha = 0.0

        signInButton.setTitleColor(Color.authenticationViewControllerButtonColor(), for: UIControlState())
        signInButton.setTitleColor(.darkGray, for: .highlighted)
        signInButton.alpha = 0.0

        codeButton.setTitleColor(Color.authenticationViewControllerButtonColor(), for: UIControlState())
        codeButton.setTitleColor(.darkGray, for: .highlighted)
        codeButton.alpha = 0.0

        MBProgressHUD.showAdded(to: view, animated: true)

        if ApiService.shared.hasCachedToken {
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)

                self.presentApplicationViewController()
            }
        } else {
            MBProgressHUD.hide(for: view, animated: true)

            logoImageView.alpha = 1.0
            signInButton.alpha = 1.0
            codeButton.alpha = 1.0
        }

        NotificationCenter.default.addObserverForName("ApplicationShouldPresentPinInputViewController") { _ in
            self.performSegue(withIdentifier: "PinInputViewControllerSegue", sender: self)
        }

        NotificationCenter.default.addObserverForName("ApplicationShouldShowInvalidCredentialsToast") { _ in
            self.showToast("The supplied credentials are invalid...")
        }

        NotificationCenter.default.addObserverForName("ApplicationUserWasAuthenticated") { _ in
            self.presentApplicationViewController()
        }
    }

    fileprivate func presentApplicationViewController() {
        performSegue(withIdentifier: "ApplicationViewControllerSegue", sender: self)

        dispatch_after_delay(1.0) {
            self.logoImageView.alpha = 1.0
            self.signInButton.alpha = 1.0
            self.codeButton.alpha = 1.0
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "ApplicationViewControllerSegue":
            (segue.destination as! ApplicationViewController).applicationViewControllerDelegate = self
        case "AuthenticationViewControllerSegue":
            assert(segue.destination is AuthenticationViewController)
        case "PinInputViewControllerSegue":
            assert(segue.destination is PinInputViewController)
            (segue.destination as! PinInputViewController).delegate = self
        case "SetPasswordViewControllerSegue":
            assert(segue.destination is SetPasswordViewController)
            (segue.destination as! SetPasswordViewController).delegate = self
        default:
            break
        }
    }

    // MARK: ApplicationViewControllerDelegate

    func dismissApplicationViewController(_ viewController: ApplicationViewController) {
        dismiss(animated: true)
    }

    // MARK: PinInputViewControllerDelegate

    func pinInputViewControllerDidComplete(_ pinInputViewController: PinInputViewController) {
        print("completed PIN input view controller \(pinInputViewController)")
    }

    func pinInputViewControllerDidExceedMaxAttempts(_ pinInputViewController: PinInputViewController) {

    }

    func isInviteRedeptionPinInputViewController(_ pinInputViewController: PinInputViewController) -> Bool {
        return true
    }

    func pinInputViewController(_ pinInputViewController: PinInputViewController, shouldAttemptInviteRedemptionWithPin pin: String) {
        if let presentingViewController = pinInputViewController.presentingViewController {
            presentingViewController.dismiss(animated: true)

            MBProgressHUD.showAdded(to: presentingViewController.view, animated: true)

            ApiService.shared.fetchInvitationWithId(pin, onSuccess: { statusCode, mappingResult in
                let invitation = mappingResult?.firstObject as! Invitation

                if let user = invitation.user {
                    let params: [String : AnyObject] = [
                        "email": user.email as AnyObject,
                        "invitation_token": pin as AnyObject,
                    ]

                    ApiService.shared.createUser(params, onSuccess: { statusCode, mappingResult in
                        MBProgressHUD.hide(for: presentingViewController.view, animated: true)
                        self.performSegue(withIdentifier: "SetPasswordViewControllerSegue", sender: self)
                    }, onError: { error, statusCode, responseString in
                        MBProgressHUD.hide(for: presentingViewController.view, animated: true)
                    })
                }
            }, onError: { error, statusCode, responseString in
                if statusCode == 404 {
                    MBProgressHUD.hide(for: presentingViewController.view, animated: true)

                    let alertController = UIAlertController(title: "Invalid PIN", message: nil, preferredStyle: .alert)

                    let tryAgainAction = UIAlertAction(title: "Try Again", style: .cancel) { action in
                        self.performSegue(withIdentifier: "PinInputViewControllerSegue", sender: self)
                    }
                    alertController.addAction(tryAgainAction)

                    let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
                    alertController.addAction(cancelAction)

                    presentingViewController.present(alertController, animated: true)
                }
            })
        }
    }

    // MARK: SetPasswordViewControllerDelegate

    func setPasswordViewController(_ viewController: SetPasswordViewController, didSetPassword success: Bool) {
        if success {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "ApplicationViewControllerSegue", sender: self)
                dispatch_after_delay(1.0) {
                    self.signInButton.alpha = 1.0
                }
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
