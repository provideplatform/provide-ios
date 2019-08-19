//
//  LinkBankAccountViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/19/19.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc protocol LinkBankAccountViewControllerDelegate: NSObjectProtocol {
    func linkBankAccountViewController(_ viewController: LinkBankAccountViewController, didLinkBankAccount bankAccount: PaymentMethod)
    func linkBankAccountViewControllerExited(_ viewController: LinkBankAccountViewController, withError: Error?)
}

class LinkBankAccountViewController: ViewController, PLKPlaidLinkViewDelegate {

    weak var delegate: LinkBankAccountViewControllerDelegate!

    private var linkViewController: PLKPlaidLinkViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        linkViewController = PLKPlaidLinkViewController(delegate: self)
        present(linkViewController, animated: false)
    }

    func linkViewController(_ linkViewController: PLKPlaidLinkViewController, didSucceedWithPublicToken publicToken: String, metadata: [String : Any]?) {
        dismiss(animated: false) { [weak self] in
            log("Successfully linked account!; public token:\(publicToken); metadata: \(metadata ?? [:])")
            let bankAccount = PaymentMethod()
            self?.delegate?.linkBankAccountViewController(self!, didLinkBankAccount: bankAccount)
        }
    }

    func linkViewController(_ linkViewController: PLKPlaidLinkViewController, didExitWithError error: Error?, metadata: [String : Any]?) {
        dismiss(animated: false) { [weak self] in
            if let error = error {
                logWarn("Failed to link account due to: \(error.localizedDescription); metadata: \(metadata ?? [:])")
                self?.delegate?.linkBankAccountViewControllerExited(self!, withError: error)
            }
            else {
                logInfo("Plaid link exited with metadata: \(metadata ?? [:])")
                self?.delegate?.linkBankAccountViewControllerExited(self!, withError: nil)
            }
        }
    }

    func linkViewController(_ linkViewController: PLKPlaidLinkViewController, didHandleEvent event: String, metadata: [String : Any]?) {
        logInfo("Link event: (event); metadata: \(metadata ?? [:])")
    }
}
