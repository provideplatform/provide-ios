//
//  AuthenticationViewControllerSegue.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class AuthenticationViewControllerSegue: UIStoryboardSegue {

    override func perform() {
        switch identifier! {
        case "AuthenticationViewControllerSegue":
            assert(sourceViewController is NavigationRootViewController)
            assert(destinationViewController is AuthenticationViewController)

            if let navigationController = (sourceViewController as UIViewController).navigationController {
                (destinationViewController as UIViewController).view.alpha = 0.0
                navigationController.navigationBar.alpha = 0.0
                navigationController.pushViewController(destinationViewController as! AuthenticationViewController, animated: false)
                (destinationViewController as! AuthenticationViewController).setupNavigationItem()

                UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseOut,
                    animations: {
                        navigationController.navigationBar.alpha = 1.0
                        (self.destinationViewController as! AuthenticationViewController).view.alpha = 1.0
                    },
                    completion: nil
                )
            }
        case "AuthenticationViewControllerUnwindSegue":
            assert(sourceViewController is AuthenticationViewController)
            assert(destinationViewController is NavigationRootViewController)

            if let navigationController = (sourceViewController as UIViewController).navigationController {
                UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseIn,
                    animations: {
                        (self.destinationViewController as UIViewController).view.alpha = 1.0
                        (self.sourceViewController as! AuthenticationViewController).view.alpha = 0.0
                        navigationController.navigationBar.alpha = 0.0
                    },
                    completion: { complete in
                        navigationController.setNavigationBarHidden(true, animated: false)
                        navigationController.popViewControllerAnimated(false)
                        navigationController.navigationBar.alpha = 1.0
                    }
                )
            }
        default:
            break
        }
    }
}
