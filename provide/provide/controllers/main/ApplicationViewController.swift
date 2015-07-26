//
//  ApplicationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol ApplicationViewControllerDelegate {
    func dismissApplicationViewController(viewController: ApplicationViewController)
}

class ApplicationViewController: ECSlidingViewController, UINavigationControllerDelegate, MenuViewControllerDelegate {

    var applicationViewControllerDelegate: ApplicationViewControllerDelegate!

    override var topViewController: UIViewController! {
        didSet {
            topViewController.view.addGestureRecognizer(panGesture)
            topViewAnchoredGesture = .Panning | .Tapping
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        topViewController = UIStoryboard("Application").instantiateInitialViewController() as! UIViewController
        (topViewController as! UINavigationController).delegate = self
    }

    private var menuContainerView: MenuContainerView!
    private var menuViewController: MenuViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        menuContainerView = MenuContainerView(frame: view.bounds)
        menuContainerView.setupMenuViewController(self)
    }

    // MARK: UINavigationControllerDelegate

    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        if viewController.isKindOfClass(TopViewController) {
            applicationViewControllerDelegate?.dismissApplicationViewController(self)
        }
    }

    // MARK: MenuViewControllerDelegate

    func navigationControllerForMenuViewController(menuViewController: MenuViewController) -> UINavigationController! {
        return topViewController as! UINavigationController
    }
}
