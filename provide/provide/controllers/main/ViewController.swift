//
//  ViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var statusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let navigationController = navigationController {
            navigationController.navigationBar.setBackgroundImage(UIImage("navbar-background"), forBarMetrics: .Default)
            navigationController.navigationBar.titleTextAttributes = AppearenceProxy.navBarTitleTextAttributes()
        }
    }

    // MARK: Activity indicator and status messaging

    func showError(errorMessage: String) {
        updateStatus(errorMessage, showActivity: false, isError: true)
        AnalyticsService.sharedService().track("Showed User an Error", properties: ["errorMessage": errorMessage])
        logError(errorMessage)
    }

    func updateStatus(text: String) {
        updateStatus(text, showActivity: !text.isEmpty, isError: false)
    }

    func showActivity() {
        updateStatus("", showActivity: true, isError: false)
    }

    func hideActivity() {
        updateStatus("", showActivity: false, isError: false)
    }

    private func updateStatus(text: String, showActivity: Bool, isError: Bool) {
        if let status = statusLabel {
            status.text = text
            status.hidden = false
            status.textColor = isError ? UIColor.redColor() : UIColor.darkTextColor()
        }

        if showActivity {
            activityIndicator?.startAnimating()
        } else {
            activityIndicator?.stopAnimating()
        }
    }

    func swizzled_viewDidAppear(animated: Bool) {
        AnalyticsService.sharedService().viewDidAppearForController(self, animated: animated)
        swizzled_viewDidAppear(animated)
    }

}
