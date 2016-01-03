//
//  QuickbooksViewController.swift
//  provide
//
//  Created by Kyle Thomas on 1/3/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class QuickbooksViewController: ViewController {

    var company: Company! {
        didSet {
            if let company = company {
                if !company.isIntegratedWithQuickbooks {
                    performSegueWithIdentifier("QuickbooksAuthorizationViewControllerSegue", sender: self)
                }
            }
        }
    }

    private var authorizationWebViewController: WebViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
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
                authorizationWebViewController.url = NSURL(string: "\(CurrentEnvironment.apiBaseUrlString)/api/quickbooks/authenticate?company_id=\(company.id)&x-api-authorization=\(token.authorizationHeaderString.splitAtString(" ").1)")
            }
        }
    }
}
