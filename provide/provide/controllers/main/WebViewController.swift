//
//  WebViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/26/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import MBProgressHUD

@objc
protocol WebViewControllerDelegate {
    @objc optional func webViewController(_ viewController: WebViewController, shouldStartLoadWithRequest request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool
    @objc optional func webViewController(_ viewController: WebViewController, webViewDidFinishLoad webView: UIWebView)
    @objc optional func webViewController(_ viewController: WebViewController, webViewDidFailWithError error: NSError)
    @objc optional func webViewControllerDismissed(_ viewController: WebViewController)
}

class WebViewController: ViewController, UIWebViewDelegate {

    weak var webViewControllerDelegate: WebViewControllerDelegate?

    @IBOutlet fileprivate weak var webView: UIWebView! {
        didSet {
            if let webView = webView, let url = url {
                let request = URLRequest(url: url)
                webView.loadRequest(request)
            } else if let html = html {
                webView.loadHTMLString(html, baseURL: URL(string: CurrentEnvironment.baseUrlString))
            }
        }
    }

    fileprivate var stopBarButtonItem: UIBarButtonItem! {
        let stopBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(WebViewController.dismiss as (WebViewController) -> () -> Void))
        stopBarButtonItem.tintColor = Color.applicationDefaultBarButtonItemTintColor()
        return stopBarButtonItem
    }

    var loadingText: String!

    var html: String! {
        didSet {
            if let html = html {
                webView?.loadHTMLString(html, baseURL: URL(string: CurrentEnvironment.baseUrlString))
            }
        }
    }

    var url: URL! {
        didSet {
            if let url = url {
                let request = URLRequest(url: url)
                webView?.loadRequest(request)
            }
        }
    }

    func loadRequest(_ url: URL, headers: [String: String]) {
        let request = NSMutableURLRequest(url: url)
        for (name, value) in headers {
            request.setValue(name, forHTTPHeaderField: value)
        }
        webView?.loadRequest(request as URLRequest)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = ""
        navigationItem.leftBarButtonItems = [stopBarButtonItem]
    }

    func dismiss() {
        if let fn = webViewControllerDelegate?.webViewControllerDismissed {
            fn(self)
        } else {
            if let navigationController = navigationController {
                navigationController.popViewController(animated: true)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.label.text = loadingText
    }

    // MARK: UIWebViewDelegate

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let shouldStartLoad = webViewControllerDelegate?.webViewController?(self, shouldStartLoadWithRequest: request, navigationType: navigationType) {
            return shouldStartLoad
        }
        return true
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        navigationItem.title = webView.stringByEvaluatingJavaScript(from: "window.document.title")
        MBProgressHUD.hide(for: view, animated: true)
        webViewControllerDelegate?.webViewController?(self, webViewDidFinishLoad: webView)
    }

    func webViewDidFailLoadWithError(_ error: NSError!) {
        MBProgressHUD.hide(for: view, animated: true)
        webViewControllerDelegate?.webViewController?(self, webViewDidFailWithError: error)
    }
}
