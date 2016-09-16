//
//  QuickbooksViewController.swift
//  provide
//
//  Created by Kyle Thomas on 1/3/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

class QuickbooksViewController: ViewController, WebViewControllerDelegate {

    var company: Company! {
        didSet {
            if let _ = company {
                if isViewLoaded {
                    reload()
                }
            }
        }
    }

    @IBOutlet fileprivate weak var instructionLabel: UILabel!
    @IBOutlet fileprivate weak var disconnectButton: UIButton!

    fileprivate var authorizationWebViewController: WebViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        instructionLabel?.alpha = 0.0

        disconnectButton.addTarget(self, action: #selector(QuickbooksViewController.disconnect(_:)), for: .touchUpInside)
        disconnectButton.alpha = 0.0

        reload()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier! == "QuickbooksAuthorizationViewControllerSegue" {
            setHasBeenPromptedToIntegrateQuickbooksAccountFlag()
            authorizationWebViewController = segue.destination as! WebViewController

            if ApiService.sharedService().hasCachedToken {
                let token = KeyChainService.sharedService().token!
                authorizationWebViewController.webViewControllerDelegate = self
                let authorizationString = token.authorizationHeaderString.components(separatedBy: " ").last!
                authorizationWebViewController.url = URL(string: "\(CurrentEnvironment.apiBaseUrlString)/api/quickbooks/authenticate?company_id=\(company.id)&x-api-authorization=\(authorizationString)")
            }
        }
    }

    func reload() {
        if !company.isIntegratedWithQuickbooks {
            performSegue(withIdentifier: "QuickbooksAuthorizationViewControllerSegue", sender: self)
        } else if company.isIntegratedWithQuickbooks {
            instructionLabel?.text = "Congrats! Quickbooks is integrated!"
            instructionLabel?.alpha = 1.0

            disconnectButton?.alpha = 1.0
        }
    }

    func disconnect(_ sender: UIButton) {
        if company.isIntegratedWithQuickbooks {

        }
    }

    // MARK: WebViewControllerDelegate

    func webViewController(_ viewController: WebViewController, shouldStartLoadWithRequest request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let url = request.url {
            if let fragment = url.fragment {
                if fragment == "/quickbooks/success" {
                    let _ = navigationController?.popViewController(animated: true) // FIXME: Does this actually work yet???
                    company.hasQuickbooksIntegration = NSNumber(value: true as Bool)
                    reload()
                    dispatch_after_delay(2.5) {
                        self.presentingViewController?.dismissViewController(true)
                    }
                }
            }
        }
        return true
    }

    func webViewControllerDismissed(_ viewController: WebViewController) {
        promptForCancellationOfQuickbooksIntegration()
    }

    fileprivate func setHasBeenPromptedToIntegrateQuickbooksAccountFlag() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey: "presentedQuickbooksAuthorizationDialog")
        userDefaults.synchronize()
    }

    fileprivate func promptForCancellationOfQuickbooksIntegration() {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .alert : .actionSheet
        let alertController = UIAlertController(title: "You did not connect your account with Quickbooks. Do you want to continue without Quickbooks integration?",
                                                message: "You can always manage your integrations from the company profile.",
                                                preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Yes, Continue Without Quickbooks", style: .cancel) { action in
            self.presentingViewController?.dismissViewController(true)
        }
        alertController.addAction(cancelAction)

        let setScaleAction = UIAlertAction(title: "Integrate With Quickbooks", style: .default, handler: nil)
        alertController.addAction(setScaleAction)

        presentViewController(alertController, animated: true)
    }
}
