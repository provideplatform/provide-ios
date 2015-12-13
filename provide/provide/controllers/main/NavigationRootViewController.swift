//
//  NavigationRootViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class NavigationRootViewController: ViewController, ApplicationViewControllerDelegate {

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
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case "ApplicationViewControllerSegue":
            (segue.destinationViewController as! ApplicationViewController).applicationViewControllerDelegate = self
            break
        case "AuthenticationViewControllerSegue":
            assert(segue.destinationViewController is AuthenticationViewController)
        default:
            break
        }
    }

    // MARK: ApplicationViewControllerDelegate

    func dismissApplicationViewController(viewController: ApplicationViewController) {
        dismissViewController(animated: true) {

        }
    }
}
