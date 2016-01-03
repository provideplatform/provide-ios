//
//  QuickbooksViewController.swift
//  provide
//
//  Created by Kyle Thomas on 1/3/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class QuickbooksViewController: ViewController, WebViewControllerDelegate {

    var company: Company! {
        didSet {
            if let _ = company {
                if viewLoaded {
                    reload()
                }
            }
        }
    }

    @IBOutlet private weak var instructionLabel: UILabel!
    @IBOutlet private weak var disconnectButton: UIButton!

    private var authorizationWebViewController: WebViewController!

    private var viewLoaded = false

    override func viewDidLoad() {
        super.viewDidLoad()

        instructionLabel?.alpha = 0.0

        disconnectButton.addTarget(self, action: "disconnect:", forControlEvents: .TouchUpInside)
        disconnectButton.alpha = 0.0

        viewLoaded = true

        if let _ = company {
            reload()
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier! == "QuickbooksAuthorizationViewControllerSegue" {
            authorizationWebViewController = segue.destinationViewController as! WebViewController

            if ApiService.sharedService().hasCachedToken {
                let token = KeyChainService.sharedService().token!
                authorizationWebViewController.webViewControllerDelegate = self
                authorizationWebViewController.url = NSURL(string: "\(CurrentEnvironment.apiBaseUrlString)/api/quickbooks/authenticate?company_id=\(company.id)&x-api-authorization=\(token.authorizationHeaderString.splitAtString(" ").1)")
            }
        }
    }

    func reload() {
        if !company.isIntegratedWithQuickbooks {
            performSegueWithIdentifier("QuickbooksAuthorizationViewControllerSegue", sender: self)
        } else {
            instructionLabel?.text = "Congrats! Quickbooks is integrated!"
            instructionLabel?.alpha = 1.0

            disconnectButton?.alpha = 1.0
        }
    }

    func disconnect(sender: UIButton) {
        if company.isIntegratedWithQuickbooks {

        }
    }

    // MARK: WebViewControllerDelegate

    func webViewController(viewController: WebViewController, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let url = request.URL {
            if let fragment = url.fragment {
                if fragment == "/quickbooks/success" {
                    navigationController?.popViewControllerAnimated(true)
                    company.hasQuickbooksIntegration = NSNumber(bool: true)
                    reload()
                    dispatch_after_delay(2.5) {
                        self.presentingViewController?.dismissViewController(animated: true)
                    }
                }
            }
        }
        return true
    }

    func webViewControllerDismissed(viewController: WebViewController) {
        promptForCancellationOfQuickbooksIntegration()
    }

    private func promptForCancellationOfQuickbooksIntegration() {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .Alert : .ActionSheet
        let alertController = UIAlertController(title: "You did not connect your account with Quickbooks. Do you want to continue without Quickbooks integration?",
                                                message: "You can always manage your integrations from the company profile.",
                                                preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Yes, Continue Without Quickbooks", style: .Cancel) { action in
            self.presentingViewController?.dismissViewController(animated: true)
        }
        alertController.addAction(cancelAction)

        let setScaleAction = UIAlertAction(title: "Integrate With Quickbooks", style: .Default, handler: nil)
        alertController.addAction(setScaleAction)

        presentViewController(alertController, animated: true)
    }
}
