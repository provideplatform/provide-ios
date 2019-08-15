//
//  AuthenticationViewControllerSegue.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import UIKit

class AuthenticationStoryboardSegue: UIStoryboardSegue {

    override func perform() {
        switch identifier! {
        case "AuthenticationViewControllerSegue":
            assert(source is NavigationRootViewController)

            if let navigationController = source.navigationController {
                destination.view.alpha = 0.0
                navigationController.navigationBar.alpha = 0.0
                navigationController.pushViewController(destination as! AuthenticationViewController, animated: false)
                (destination as! AuthenticationViewController).setupNavigationItem()

                UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut, animations: { [weak self] in
                    navigationController.navigationBar.alpha = 1.0
                    self?.destination.view.alpha = 1.0
                })
            }
        case "AuthenticationViewControllerUnwindSegue":
            assert(destination is NavigationRootViewController)

            if let navigationController = source.navigationController {
                UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseIn, animations: { [weak self] in
                    self?.destination.view.alpha = 1.0
                    self?.source.view.alpha = 0.0
                    navigationController.navigationBar.alpha = 0.0
                }, completion: { complete in
                    navigationController.setNavigationBarHidden(true, animated: false)
                    navigationController.popViewController(animated: false)
                    navigationController.navigationBar.alpha = 1.0
                })
            }
        case "SetPasswordViewControllerSegue":
            assert(source is NavigationRootViewController)

            if let navigationController = source.navigationController {
                destination.view.alpha = 0.0
                navigationController.navigationBar.alpha = 0.0
                navigationController.pushViewController(destination as! SetPasswordViewController, animated: false)
                (destination as! SetPasswordViewController).setupNavigationItem()

                UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut, animations: { [weak self] in
                    navigationController.navigationBar.alpha = 1.0
                    self?.destination.view.alpha = 1.0
                })
            }
        case "SetPasswordViewControllerUnwindSegue":
            assert(destination is NavigationRootViewController)

            if let navigationController = source.navigationController {
                UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseIn, animations: { [weak self] in
                    self?.destination.view.alpha = 1.0
                    self?.source.view.alpha = 0.0
                    navigationController.navigationBar.alpha = 0.0
                }, completion: { complete in
                    navigationController.setNavigationBarHidden(true, animated: false)
                    navigationController.popViewController(animated: false)
                    navigationController.navigationBar.alpha = 1.0
                })
            }
        case "SignupViewControllerSegue":
            assert(source is NavigationRootViewController)

            if let navigationController = source.navigationController {
                destination.view.alpha = 0.0
                navigationController.navigationBar.alpha = 0.0
                navigationController.pushViewController(destination as! SignupViewController, animated: false)
                (destination as! SignupViewController).setupNavigationItem()

                UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut, animations: { [weak self] in
                    navigationController.navigationBar.alpha = 1.0
                    self?.destination.view.alpha = 1.0
                })
            }
        case "SignupViewControllerUnwindSegue":
            assert(destination is NavigationRootViewController)

            if let navigationController = source.navigationController {
                UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseIn, animations: { [weak self] in
                    self?.destination.view.alpha = 1.0
                    self?.source.view.alpha = 0.0
                    navigationController.navigationBar.alpha = 0.0
                }, completion: { complete in
                    navigationController.setNavigationBarHidden(true, animated: false)
                    navigationController.popViewController(animated: false)
                    navigationController.navigationBar.alpha = 1.0
                })
            }
        default:
            break
        }
    }
}
