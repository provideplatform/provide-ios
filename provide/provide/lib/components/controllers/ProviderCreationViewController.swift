//
//  ProviderCreationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/12/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol ProviderCreationViewControllerDelegate {
    func providerCreationViewController(viewController: ProviderCreationViewController, didCreateProvider provider: Provider)
}

class ProviderCreationViewController: UITableViewController, UITextFieldDelegate {

    var delegate: ProviderCreationViewControllerDelegate!

    @IBOutlet private weak var nameTextField: UITextField!

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 {
            let provider = Provider()
            provider.companyId = 0 // FIXME!! customer.companyId
            provider.name = nameTextField?.text

            let providerIsValid = provider.companyId > 0 && provider.name != nil && provider.name.length > 0

            if providerIsValid {
                for view in tableView.cellForRowAtIndexPath(indexPath)!.contentView.subviews {
                    if view.isKindOfClass(UIActivityIndicatorView) {
                        (view as! UIActivityIndicatorView).startAnimating()
                    } else if view.isKindOfClass(UILabel) {
                        view.alpha = 0.0
                    }
                }

                provider.save(
                    onSuccess: { statusCode, mappingResult in
                        if statusCode == 201 {
                            provider.reload(
                                onSuccess: { statusCode, mappingResult in
                                    self.activityIndicatorView?.stopAnimating()
                                    self.delegate?.providerCreationViewController(self, didCreateProvider: mappingResult.firstObject as! Provider)
                                },
                                onError: { error, statusCode, responseString in
                                    self.activityIndicatorView?.stopAnimating()
                                }
                            )
                        }
                    },
                    onError: { error, statusCode, responseString in
                        self.activityIndicatorView?.stopAnimating()
                    }
                )
            }
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == 2 {
            tableView.cellForRowAtIndexPath(indexPath)!.alpha = 0.8
        }
        return indexPath
    }

    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 2 {
            tableView.cellForRowAtIndexPath(indexPath)!.alpha = 1.0
        }
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == nameTextField {
            if let name = textField.text {
                return name.length > 0
            }
        }
        return false
    }
}
