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

    func dismissViewControllerAnimated(flag: Bool) {
        dismissViewControllerAnimated(flag, completion: nil)
    }

    func dismissViewController(animated: Bool = false, completion: VoidBlock? = nil) {
        dismissViewControllerAnimated(animated, completion: completion)
    }
}
