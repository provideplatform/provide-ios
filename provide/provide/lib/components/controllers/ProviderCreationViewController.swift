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
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var mobileNumberTextField: UITextField!

    private var dismissItem: UIBarButtonItem! {
        let dismissItem = UIBarButtonItem(title: "DISMISS", style: .Plain, target: self, action: "dismiss:")
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return dismissItem
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "ADD SERVICE PROVIDER"

        if !isIPad() {
            navigationItem.leftBarButtonItems = [dismissItem]
        }
    }

    func dismiss(sender: UIBarButtonItem) {
        if let navigationController = navigationController {
            if navigationController.viewControllers.count > 1 {
                navigationController.popViewControllerAnimated(true)
            } else {
                navigationController.presentingViewController?.dismissViewController(animated: true)
            }
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == tableView.numberOfSections - 1 {
            let user = currentUser()
            if user.defaultCompanyId > 0 {
                createProviderWithCompanyId(user.defaultCompanyId)
            } else {
                print("WARNING: this user is associated with multiple companies as a provider so cannot attempt creation without user input")

//                if user.providers == nil {
//                    if user.providerIds.count == 1 {
//                        user.reloadProviders(
//                            { statusCode, mappingResult in
//                                if user.providers.count == 1 {
//                                    self.createProviderWithCompanyId(user.providers.first!.companyId)
//                                }
//                            }, onError: { error, statusCode, responseString in
//
//                            }
//                        )
//                    }
//                }
            }
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == tableView.numberOfSections - 1 {
            tableView.cellForRowAtIndexPath(indexPath)!.alpha = 0.8
        }
        return indexPath
    }

    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == tableView.numberOfSections - 1 {
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

    private func createProviderWithCompanyId(companyId: Int) {
        let provider = Provider()
        provider.companyId = companyId
        provider.name = nameTextField?.text

        let contact = Contact()
        contact.name = nameTextField?.text
        contact.email = emailTextField?.text
        contact.mobile = mobileNumberTextField?.text
        provider.contact = contact

        let providerIsValid = provider.companyId > 0 && provider.name != nil && provider.name.length > 0 && contact.email != nil && contact.email.length > 0

        if providerIsValid {
            showActivityIndicator()

            provider.save(
                onSuccess: { statusCode, mappingResult in
                    if statusCode == 201 {
                        provider.reload(
                            onSuccess: { statusCode, mappingResult in
                                self.hideActivityIndicator()
                                self.delegate?.providerCreationViewController(self, didCreateProvider: mappingResult.firstObject as! Provider)
                            },
                            onError: { error, statusCode, responseString in
                                self.hideActivityIndicator()
                            }
                        )
                    }
                },
                onError: { error, statusCode, responseString in
                    self.hideActivityIndicator()

                    if statusCode == 422 {
                        if let response = responseString.toJSONObject() {
                            if let errorsIndex = response.indexForKey("errors") {
                                if let errors = response[errorsIndex].1 as? [String : [String]] {
                                    for key in errors.keys.generate() {
                                        for value in errors[key]! {
                                            self.showToast("\(key) \(value)")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            )
        } else {
            hideActivityIndicator()
        }
    }

    private func showActivityIndicator() {
        let section = tableView.numberOfSections - 1
        for view in tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: section))!.contentView.subviews {
            if view.isKindOfClass(UIActivityIndicatorView) {
                (view as! UIActivityIndicatorView).startAnimating()
            } else if view.isKindOfClass(UILabel) {
                view.alpha = 0.0
            }
        }
    }

    private func hideActivityIndicator() {
        let section = tableView.numberOfSections - 1
        for view in tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: section))!.contentView.subviews {
            if view.isKindOfClass(UIActivityIndicatorView) {
                (view as! UIActivityIndicatorView).stopAnimating()
            } else if view.isKindOfClass(UILabel) {
                view.alpha = 1.0
            }
        }
    }
}
