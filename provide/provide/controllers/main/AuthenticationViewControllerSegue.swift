//
//  AuthenticationViewControllerSegue.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class AuthenticationViewControllerSegue: UIStoryboardSegue {

    override func perform() {
        switch identifier! {
        case "AuthenticationViewControllerSegue":
            assert(source is NavigationRootViewController)
            assert(destination is AuthenticationViewController)

            if let navigationController = source.navigationController {
                destination.view.alpha = 0.0
                navigationController.navigationBar.alpha = 0.0
                navigationController.pushViewController(destination as! AuthenticationViewController, animated: false)
                (destination as! AuthenticationViewController).setupNavigationItem()

                UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut,
                    animations: {
                        navigationController.navigationBar.alpha = 1.0
                        (self.destination as! AuthenticationViewController).view.alpha = 1.0
                    },
                    completion: nil
                )
            }
        case "AuthenticationViewControllerUnwindSegue":
            assert(source is AuthenticationViewController)
            assert(destination is NavigationRootViewController)

            if let navigationController = source.navigationController {
                UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseIn,
                    animations: {
                        self.destination.view.alpha = 1.0
                        (self.source as! AuthenticationViewController).view.alpha = 0.0
                        navigationController.navigationBar.alpha = 0.0
                    },
                    completion: { complete in
                        navigationController.setNavigationBarHidden(true, animated: false)
                        navigationController.popViewController(animated: false)
                        navigationController.navigationBar.alpha = 1.0
                    }
                )
            }
        case "SetPasswordViewControllerSegue":
            assert(source is NavigationRootViewController)
            assert(destination is SetPasswordViewController)

            if let navigationController = source.navigationController {
                destination.view.alpha = 0.0
                navigationController.navigationBar.alpha = 0.0
                navigationController.pushViewController(destination as! SetPasswordViewController, animated: false)
                (destination as! SetPasswordViewController).setupNavigationItem()

                UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut,
                    animations: {
                        navigationController.navigationBar.alpha = 1.0
                        (self.destination as! SetPasswordViewController).view.alpha = 1.0
                    },
                    completion: nil
                )
            }
        case "SetPasswordViewControllerUnwindSegue":
            assert(source is SetPasswordViewController)
            assert(destination is NavigationRootViewController)

            if let navigationController = source.navigationController {
                UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseIn,
                    animations: {
                        self.destination.view.alpha = 1.0
                        (self.source as! SetPasswordViewController).view.alpha = 0.0
                        navigationController.navigationBar.alpha = 0.0
                    },
                    completion: { complete in
                        navigationController.setNavigationBarHidden(true, animated: false)
                        navigationController.popViewController(animated: false)
                        navigationController.navigationBar.alpha = 1.0
                    }
                )
            }
        default:
            break
        }
    }
}
