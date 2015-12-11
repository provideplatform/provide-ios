//
//  UIViewControllerExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

extension UIViewController {

    // MARK: Child view controller presentation

    func presentViewController(viewControllerToPresent: UIViewController, animated: Bool) {
        presentViewController(viewControllerToPresent, animated: animated, completion: nil)
    }

    func dismissViewController(animated animated: Bool, completion: VoidBlock? = nil) {
        dismissViewControllerAnimated(animated, completion: completion)
    }

    // MARK: MBProgressHUD

    func showHUD() {
        dispatch_after_delay(0.0) {
            self.showHUD(inView: self.view)
        }
    }

    func showHUD(inView view: UIView) {
        var hud: MBProgressHUD! = MBProgressHUD(forView: view)

        if hud == nil {
            hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        } else {
            hud.show(true)
        }
    }

    func showHUDWithText(text: String) {
        var hud: MBProgressHUD! = MBProgressHUD(forView: view)

        if hud == nil {
            hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        } else {
            hud.show(true)
        }

        hud.labelText = text
    }

    func hideHUD() {
        dispatch_after_delay(0.0) {
            self.hideHUD(inView: self.view)
        }
    }

    func hideHUD(inView view: UIView!) {
        if let hud = MBProgressHUD(forView: view) {
            hud.hide(true)
        }
    }

    func hideHUDWithText(text: String, completion: VoidBlock? = nil) {
        let hud = MBProgressHUD(forView: view)
        hud.mode = .Text
        hud.labelText = text

        if let completionBlock = completion {
            dispatch_after_delay(1.5) {
                hud.hide(true)
                completionBlock()
            }
        } else {
            hud.hide(true, afterDelay: 1.5)
        }
    }

    // MARK: UIAlertController

    func showToast(title: String, dismissAfter delay: NSTimeInterval = 1.5) {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .Alert)
        presentViewController(alertController, animated: true)

        dispatch_after_delay(delay) {
            self.dismissViewController(animated: true)
        }
    }
}
