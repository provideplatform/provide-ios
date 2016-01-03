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
            if let company = company {
                if !company.isIntegratedWithQuickbooks {
                    performSegueWithIdentifier("QuickbooksAuthorizationViewControllerSegue", sender: self)
                } else {
                    reload()
                }
            }
        }
    }

    @IBOutlet private weak var instructionLabel: UILabel!
    
    private var authorizationWebViewController: WebViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        instructionLabel.alpha = 0.0
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
        instructionLabel.text = "Congrats! Quickbooks is integrated!"
        instructionLabel.alpha = 1.0
    }

    // MARK: WebViewControllerDelegate

    func webViewController(viewController: WebViewController, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let url = request.URL {
            if let fragment = url.fragment {
                if fragment == "/quickbooks/success" {
                    navigationController?.popViewControllerAnimated(true)
                    reload()
                    dispatch_after_delay(2.5) {
                        self.presentingViewController?.dismissViewController(animated: true)
                    }
                }
            }
        }
        return true
    }
}
