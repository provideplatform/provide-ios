//
//  WebViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/26/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import MBProgressHUD

class WebViewController: ViewController, UIWebViewDelegate {

    @IBOutlet private weak var webView: UIWebView! {
        didSet {
            if let webView = webView, let url = url {
                let request = URLRequest(url: url)
                webView.loadRequest(request)
            } else if let html = html {
                webView.loadHTMLString(html, baseURL: URL(string: CurrentEnvironment.baseUrlString))
            }
        }
    }

    private var stopBarButtonItem: UIBarButtonItem! {
        let stopBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(WebViewController.dismiss as (WebViewController) -> () -> Void))
        stopBarButtonItem.tintColor = Color.applicationDefaultBarButtonItemTintColor()
        return stopBarButtonItem
    }

    private var loadingText: String!

    private var html: String! {
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

    private func loadRequest(_ url: URL, headers: [String: String]) {
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

    @objc func dismiss() {
        navigationController?.popViewController(animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.label.text = loadingText
    }

    // MARK: UIWebViewDelegate

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return true
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        navigationItem.title = webView.stringByEvaluatingJavaScript(from: "window.document.title")
        MBProgressHUD.hide(for: view, animated: true)
    }

    func webViewDidFailLoadWithError(_ error: NSError!) {
        MBProgressHUD.hide(for: view, animated: true)
    }
}
