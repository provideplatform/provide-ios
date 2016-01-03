//
//  WebViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/26/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol WebViewControllerDelegate {
    optional func webViewController(viewController: WebViewController, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool
    optional func webViewController(viewController: WebViewController, webViewDidFinishLoad webView: UIWebView)
    optional func webViewController(viewController: WebViewController, webViewDidFailWithError error: NSError)
}

class WebViewController: ViewController, UIWebViewDelegate {

    var webViewControllerDelegate: WebViewControllerDelegate!

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

    var url: NSURL! {
        didSet {
            if let url = url {
                let request = NSURLRequest(URL: url)
                webView?.loadRequest(request)
            }
        }
    }

    func loadRequest(url: NSURL, headers: [String : String]) {
        let request = NSMutableURLRequest(URL: url)
        for (name, value) in headers {
            request.setValue(name, forHTTPHeaderField: value)
        }
        webView?.loadRequest(request)
    }

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

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let shouldStartLoad = webViewControllerDelegate?.webViewController?(self, shouldStartLoadWithRequest: request, navigationType: navigationType) {
            return shouldStartLoad
        }
        return false
    }

    func webViewDidFinishLoad(webView: UIWebView) {
        navigationItem.title = webView.stringByEvaluatingJavaScriptFromString("window.document.title")
        MBProgressHUD.hideAllHUDsForView(view, animated: true)
        webViewControllerDelegate?.webViewController?(self, webViewDidFinishLoad: webView)
    }

    func webViewDidFailLoadWithError(error: NSError!) {
        MBProgressHUD.hideAllHUDsForView(view, animated: true)
        webViewControllerDelegate?.webViewController?(self, webViewDidFailWithError: error)
    }
}
