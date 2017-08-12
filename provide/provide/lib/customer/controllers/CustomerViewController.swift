//
//  CustomerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/12/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

class CustomerViewController: ViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true

        setupBarButtonItems()
    }

    fileprivate func setupBarButtonItems() {
        setupMenuBarButtonItem()
        setupMessagesBarButtonItem()
    }

    fileprivate func setupMenuBarButtonItem() {
        let menuIconImage = FAKFontAwesome.naviconIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0)).withRenderingMode(.alwaysTemplate)
        let menuBarButtonItem = NavigationBarButton.barButtonItemWithImage(menuIconImage, target: self, action: "menuButtonTapped:")
        navigationItem.leftBarButtonItem = menuBarButtonItem
    }

    fileprivate func setupMessagesBarButtonItem() {
        //        let messageIconImage = FAKFontAwesome.envelopeOIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0))
        //        let messagesBarButtonItem = NavigationBarButton.barButtonItemWithImage(messageIconImage, target: self, action: "messageButtonTapped:")
        //        navigationItem.rightBarButtonItem = messagesBarButtonItem
    }

    @objc fileprivate func menuButtonTapped(_ sender: UIBarButtonItem) {
        NotificationCenter.default.postNotificationName("MenuContainerShouldOpen")
    }

    @objc fileprivate func messageButtonTapped(_ sender: UIBarButtonItem) {
        let messagesNavCon = UIStoryboard("Messages").instantiateInitialViewController() as? UINavigationController
        presentViewController(messagesNavCon!, animated: true)
    }
}
