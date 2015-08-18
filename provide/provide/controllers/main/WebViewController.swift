//
//  WebViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/26/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class WebViewController: ViewController, UIWebViewDelegate {

    @IBOutlet private weak var webView: UIWebView!

    private var stopBarButtonItem: UIBarButtonItem! {
        let stopBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: "dismiss")
        stopBarButtonItem.tintColor = UIColor.whiteColor()
        return stopBarButtonItem
    }

    var loadingText: String!

    var html: String! {
        didSet {
            if let webView = webView {
                webView.loadHTMLString(html, baseURL: NSURL(string: CurrentEnvironment.baseUrlString))
            }
        }
    }

    var url: NSURL!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = ""
        navigationItem.leftBarButtonItems = [stopBarButtonItem]
    }

    func dismiss() {
        if let navigationController = navigationController {
            navigationController.popViewControllerAnimated(true)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.labelText = loadingText

        if url != nil {
            let request = NSURLRequest(URL: url)
            webView.loadRequest(request)
        } else if html != nil {
            webView.loadHTMLString(html, baseURL: nil)
        }
    }

    // MARK: UIWebViewDelegate

    func webViewDidFinishLoad(webView: UIWebView) {
        navigationItem.title = webView.stringByEvaluatingJavaScriptFromString("window.document.title")
        MBProgressHUD.hideAllHUDsForView(view, animated: true)
    }

    func webViewDidFailLoadWithError(error: NSError!) {
        MBProgressHUD.hideAllHUDsForView(view, animated: true)
    }
}
