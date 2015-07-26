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

class ApplicationViewController: ViewController, UINavigationControllerDelegate, MenuViewControllerDelegate {

    var delegate: ApplicationViewControllerDelegate!

    private var menuContainerView: MenuContainerView!
    private var menuViewController: MenuViewController!

    private var topViewController: UINavigationController!

    override func viewDidLoad() {
        super.viewDidLoad()

        topViewController = UIStoryboard("Application").instantiateInitialViewController() as! UINavigationController
        topViewController.delegate = self
        view.addSubview(topViewController.view)

        menuContainerView = MenuContainerView(frame: view.bounds)
        menuContainerView.setupMenuViewController(self)
    }

    // MARK: UINavigationControllerDelegate

    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        if viewController.isKindOfClass(TopViewController) {
            delegate?.dismissApplicationViewController(self)
        }
    }

    // MARK: MenuViewControllerDelegate

    func navigationControllerForMenuViewController(menuViewController: MenuViewController) -> UINavigationController! {
        return topViewController
    }
}
