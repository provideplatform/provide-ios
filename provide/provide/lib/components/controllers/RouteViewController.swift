//
//  RouteViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/20/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol RouteViewControllerDelegate {
    func routeForViewController(viewController: ViewController!) -> Route!
    func navigationControllerForViewController(viewController: ViewController!) -> UINavigationController!
}

class RouteViewController: ViewController {

    var delegate: RouteViewControllerDelegate!

    var route: Route! {
        return delegate?.routeForViewController(self)
    }

    private var dismissItem: UIBarButtonItem! {
        let dismissItem = UIBarButtonItem(title: "DISMISS", style: .Plain, target: self, action: "dismiss")
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return dismissItem
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshNavigationItem()
    }

    func refreshNavigationItem() {
        navigationItem.leftBarButtonItems = [dismissItem]

        if let navigationController = delegate?.navigationControllerForViewController(self) {
            navigationController.setNavigationBarHidden(false, animated: true)
        }
    }

    func clearNavigationItem() {
        navigationItem.hidesBackButton = true
        navigationItem.prompt = nil
        navigationItem.leftBarButtonItems = []
        navigationItem.rightBarButtonItems = []
    }

    func dismiss() {
        clearNavigationItem()

        if let navigationController = delegate?.navigationControllerForViewController(self) {
            navigationController.popViewControllerAnimated(true)
        }
    }
}
