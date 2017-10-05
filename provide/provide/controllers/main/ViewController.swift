//
//  ViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

class ViewController: UIViewController {

    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet fileprivate weak var statusLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    // MARK: Activity indicator and status messaging

    func showError(_ errorMessage: String) {
        updateStatus(errorMessage, showActivity: false, isError: true)
        AnalyticsService.sharedService().track("Showed User an Error", properties: ["errorMessage": errorMessage as AnyObject] as [String: AnyObject])
        logWarn(errorMessage)
    }

    func updateStatus(_ text: String) {
        updateStatus(text, showActivity: !text.isEmpty, isError: false)
    }

    func showActivity() {
        updateStatus("", showActivity: true, isError: false)
    }

    func hideActivity() {
        updateStatus("", showActivity: false, isError: false)
    }

    fileprivate func updateStatus(_ text: String, showActivity: Bool, isError: Bool) {
        if let status = statusLabel {
            status.text = text
            status.isHidden = false
            status.textColor = isError ? .red : .darkText
        }

        if showActivity {
            activityIndicator?.startAnimating()
        } else {
            activityIndicator?.stopAnimating()
        }
    }

    func swizzled_viewDidAppear(_ animated: Bool) {
        AnalyticsService.sharedService().viewDidAppearForController(self, animated: animated)
        swizzled_viewDidAppear(animated)
    }
}
