//
//  NavigationRootViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class NavigationRootViewController: ViewController, ApplicationViewControllerDelegate, PinInputViewControllerDelegate {

    @IBOutlet private var logoImageView: UIImageView!
    @IBOutlet private var signInButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Color.applicationDefaultBackgroundImageColor(view.frame)

        signInButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        signInButton.setTitleColor(UIColor.darkGrayColor(), forState: .Highlighted)
        signInButton.alpha = 0.0

        if ApiService.sharedService().hasCachedToken {
            dispatch_after_delay(0.0) {
                self.performSegueWithIdentifier("ApplicationViewControllerSegue", sender: self)
                dispatch_after_delay(1.0) {
                    self.signInButton.alpha = 1.0
                }
            }
        } else {
            signInButton.alpha = 1.0
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

            let params: [String : AnyObject] = [
                "invitation_token": pin
            ]

            ApiService.sharedService().createUser(params,
                onSuccess: { statusCode, mappingResult in

                },
                onError: { error, statusCode, responseString in

                }
            )
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
