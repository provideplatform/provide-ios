//
//  NavigationRootViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class NavigationRootViewController: ViewController,
                                    ApplicationViewControllerDelegate,
                                    SetPasswordViewControllerDelegate,
                                    PinInputViewControllerDelegate {

    @IBOutlet private var logoImageView: UIImageView!
    @IBOutlet private var signInButton: UIButton!
    @IBOutlet private var codeButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.whiteColor()

        logoImageView.alpha = 0.0

        signInButton.setTitleColor(Color.authenticationViewControllerButtonColor(), forState: .Normal)
        signInButton.setTitleColor(UIColor.darkGrayColor(), forState: .Highlighted)
        signInButton.alpha = 0.0

        codeButton.setTitleColor(Color.authenticationViewControllerButtonColor(), forState: .Normal)
        codeButton.setTitleColor(UIColor.darkGrayColor(), forState: .Highlighted)
        codeButton.alpha = 0.0

        MBProgressHUD.showHUDAddedTo(view, animated: true)

        if ApiService.sharedService().hasCachedToken {
            dispatch_after_delay(0.0) {
                MBProgressHUD.hideHUDForView(self.view, animated: true)

                self.performSegueWithIdentifier("ApplicationViewControllerSegue", sender: self)
                dispatch_after_delay(1.0) {
                    self.logoImageView.alpha = 1.0
                    self.signInButton.alpha = 1.0
                    self.codeButton.alpha = 1.0
                }
            }
        } else {
            MBProgressHUD.hideHUDForView(view, animated: true)

            logoImageView.alpha = 1.0
            signInButton.alpha = 1.0
            codeButton.alpha = 1.0
        }

        NSNotificationCenter.defaultCenter().addObserverForName("ApplicationShouldPresentPinInputViewController") { _ in
            self.performSegueWithIdentifier("PinInputViewControllerSegue", sender: self)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case "ApplicationViewControllerSegue":
            (segue.destinationViewController as! ApplicationViewController).applicationViewControllerDelegate = self
            break
        case "AuthenticationViewControllerSegue":
            assert(segue.destinationViewController is AuthenticationViewController)
        case "PinInputViewControllerSegue":
            assert(segue.destinationViewController is PinInputViewController)
            (segue.destinationViewController as! PinInputViewController).delegate = self
        case "SetPasswordViewControllerSegue":
            assert(segue.destinationViewController is SetPasswordViewController)
            (segue.destinationViewController as! SetPasswordViewController).delegate = self
        default:
            break
        }
    }

    // MARK: ApplicationViewControllerDelegate

    func dismissApplicationViewController(viewController: ApplicationViewController) {
        dismissViewController(animated: true) {

        }
    }

    // MARK: PinInputViewControllerDelegate

    func pinInputViewControllerDidComplete(pinInputViewController: PinInputViewController) {
        print("completed PIN input view controller \(pinInputViewController)")
    }

    func pinInputViewControllerDidExceedMaxAttempts(pinInputViewController: PinInputViewController) {

    }

    func isInviteRedeptionPinInputViewController(pinInputViewController: PinInputViewController) -> Bool {
        return true
    }

    func pinInputViewController(pinInputViewController: PinInputViewController, shouldAttemptInviteRedemptionWithPin pin: String) {
        if let presentingViewController = pinInputViewController.presentingViewController {
            presentingViewController.dismissViewController(animated: true)

            MBProgressHUD.showHUDAddedTo(presentingViewController.view, animated: true)

            ApiService.sharedService().fetchInvitationWithId(pin,
                onSuccess: { statusCode, mappingResult in
                    let invitation = mappingResult.firstObject as! Invitation

                    if let user = invitation.user {
                        let params: [String : AnyObject] = [
                            "email": user.email,
                            "invitation_token": pin
                        ]

                        ApiService.sharedService().createUser(params,
                            onSuccess: { statusCode, mappingResult in
                                MBProgressHUD.hideAllHUDsForView(presentingViewController.view, animated: true)
                                self.performSegueWithIdentifier("SetPasswordViewControllerSegue", sender: self)
                            },
                            onError: { error, statusCode, responseString in
                                MBProgressHUD.hideAllHUDsForView(presentingViewController.view, animated: true)
                            }
                        )
                    }
                },
                onError: { error, statusCode, responseString in
                    if statusCode == 404 {
                        MBProgressHUD.hideAllHUDsForView(presentingViewController.view, animated: true)

                        let alertController = UIAlertController(title: "Invalid PIN", message: nil, preferredStyle: .Alert)

                        let tryAgainAction = UIAlertAction(title: "Try Again", style: .Cancel) { action in
                            self.performSegueWithIdentifier("PinInputViewControllerSegue", sender: self)
                        }
                        alertController.addAction(tryAgainAction)

                        let cancelAction = UIAlertAction(title: "Cancel", style: .Destructive, handler: nil)
                        alertController.addAction(cancelAction)

                        presentingViewController.presentViewController(alertController, animated: true)
                    }
                }
            )
        }
    }

    // MARK: SetPasswordViewControllerDelegate

    func setPasswordViewController(viewController: SetPasswordViewController, didSetPassword success: Bool) {
        if success {
            dispatch_after_delay(0.0) {
                self.performSegueWithIdentifier("ApplicationViewControllerSegue", sender: self)
                dispatch_after_delay(1.0) {
                    self.signInButton.alpha = 1.0
                }
            }
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
