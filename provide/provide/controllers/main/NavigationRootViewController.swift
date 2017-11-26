//
//  NavigationRootViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import MBProgressHUD

class NavigationRootViewController: ViewController, ApplicationViewControllerDelegate, FBSDKLoginButtonDelegate, PinInputViewControllerDelegate {

    @IBOutlet private var logoImageView: UIImageView!
    @IBOutlet private var signInButton: UIButton!
    @IBOutlet private var codeButton: UIButton!

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
            DispatchQueue.main.async { [weak self] in
                if let strongSelf = self {
                    MBProgressHUD.hide(for: strongSelf.view, animated: true)
                    strongSelf.presentApplicationViewController()
                }
            }
        } else {
            MBProgressHUD.hide(for: view, animated: true)

            logoImageView.alpha = 1.0
            signInButton.alpha = 1.0
            codeButton.alpha = 1.0
        }

        KTNotificationCenter.addObserver(forName: .ApplicationShouldPresentPinInputViewController) { [weak self] _ in
            if let strongSelf = self {
                strongSelf.performSegue(withIdentifier: "PinInputViewControllerSegue", sender: strongSelf)
            }
        }

        KTNotificationCenter.addObserver(forName: .ApplicationShouldShowInvalidCredentialsToast) { [weak self] _ in
            self?.showToast("The supplied credentials are invalid...")
        }

        KTNotificationCenter.addObserver(forName: .ApplicationUserWasAuthenticated) { [weak self] _ in
            self?.presentApplicationViewController()
        }
    }

    private func presentApplicationViewController() {
        performSegue(withIdentifier: "ApplicationViewControllerSegue", sender: self)

        dispatch_after_delay(1.0) { [weak self] in
            self?.logoImageView.alpha = 1.0
            self?.signInButton.alpha = 1.0
            self?.codeButton.alpha = 1.0
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "ApplicationViewControllerSegue":
            (segue.destination as! ApplicationViewController).applicationViewControllerDelegate = self
        case "AuthenticationViewControllerSegue":
            assert(segue.destination is AuthenticationViewController)
        case "PinInputViewControllerSegue":
            (segue.destination as! PinInputViewController).delegate = self
        case "SetPasswordViewControllerSegue":
            (segue.destination as! SetPasswordViewController).configure(onPasswordSet: onPasswordSet)
        default:
            break
        }
    }

    // MARK: ApplicationViewControllerDelegate

    func dismissApplicationViewController(_ viewController: ApplicationViewController) {
        dismiss(animated: true)
    }

    // MARK: FBSDKLoginButtonDelegate

    func loginButtonWillLogin(_ loginButton: FBSDKLoginButton!) -> Bool {
        logInfo("Attempting to login using Facebook")
        return true
    }

    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if let result = result {
            logInfo("Facebook login completed with result: \(result)")
        } else if let error = error {
            logWarn("Facebook login failed with error: \(error)")
        }
    }

    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        logWarn("No-op for Facebook logout")
    }

    // MARK: PinInputViewControllerDelegate

    func pinInputViewControllerDidComplete(_ pinInputViewController: PinInputViewController) {
        logmoji("🔢", "completed PIN input view controller \(pinInputViewController)")
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
                    let params = [
                        "email": user.email!,
                        "invitation_token": pin,
                    ]

                    ApiService.shared.createUser(params, onSuccess: { [weak self] statusCode, mappingResult in
                        if let strongSelf = self {
                            MBProgressHUD.hide(for: presentingViewController.view, animated: true)
                            strongSelf.performSegue(withIdentifier: "SetPasswordViewControllerSegue", sender: strongSelf)
                        }
                    }, onError: { error, statusCode, responseString in
                        MBProgressHUD.hide(for: presentingViewController.view, animated: true)
                    })
                }
            }, onError: { error, statusCode, responseString in
                if statusCode == 404 {
                    MBProgressHUD.hide(for: presentingViewController.view, animated: true)

                    let alertController = UIAlertController(title: "Invalid PIN", message: nil, preferredStyle: .alert)

                    let tryAgainAction = UIAlertAction(title: "Try Again", style: .cancel) { [weak self] action in
                        if let strongSelf = self {
                            strongSelf.performSegue(withIdentifier: "PinInputViewControllerSegue", sender: strongSelf)
                        }
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

    func onPasswordSet(success: Bool) {
        if success {
            DispatchQueue.main.async { [weak self] in
                if let strongSelf = self {
                    strongSelf.performSegue(withIdentifier: "ApplicationViewControllerSegue", sender: strongSelf)
                    dispatch_after_delay(1.0) { [weak self] in
                        self?.signInButton.alpha = 1.0
                    }
                }
            }
        }
    }
}
