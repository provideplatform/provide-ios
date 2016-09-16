//
//  ProviderCreationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/12/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

protocol ProviderCreationViewControllerDelegate {
    func providerCreationViewController(_ viewController: ProviderCreationViewController, didCreateProvider provider: Provider)
}

class ProviderCreationViewController: UITableViewController, UITextFieldDelegate {

    var delegate: ProviderCreationViewControllerDelegate!

    @IBOutlet fileprivate weak var nameTextField: UITextField!
    @IBOutlet fileprivate weak var emailTextField: UITextField!
    @IBOutlet fileprivate weak var mobileNumberTextField: UITextField!

    fileprivate var dismissItem: UIBarButtonItem! {
        let dismissItem = UIBarButtonItem(title: "DISMISS", style: .plain, target: self, action: #selector(ProviderCreationViewController.dismiss(_:)))
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: UIControlState())
        return dismissItem
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "ADD SERVICE PROVIDER"

        if !isIPad() {
            navigationItem.leftBarButtonItems = [dismissItem]
        }
    }

    func dismiss(_ sender: UIBarButtonItem) {
        if let navigationController = navigationController {
            if navigationController.viewControllers.count > 1 {
                navigationController.popViewController(animated: true)
            } else {
                navigationController.presentingViewController?.dismissViewController(true)
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == tableView.numberOfSections - 1 {
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

        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if (indexPath as NSIndexPath).section == tableView.numberOfSections - 1 {
            tableView.cellForRow(at: indexPath)!.alpha = 0.8
        }
        return indexPath
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section == tableView.numberOfSections - 1 {
            tableView.cellForRow(at: indexPath)!.alpha = 1.0
        }
    }

    // MARK: UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            if let name = textField.text {
                return name.length > 0
            }
        }
        return false
    }

    fileprivate func createProviderWithCompanyId(_ companyId: Int) {
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
                { statusCode, mappingResult in
                    if statusCode == 201 {
                        provider.reload(
                            { statusCode, mappingResult in
                                self.hideActivityIndicator()
                                self.delegate?.providerCreationViewController(self, didCreateProvider: mappingResult?.firstObject as! Provider)
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
                            if let errorsIndex = response.index(forKey: "errors") {
                                if let errors = response[errorsIndex].1 as? [String : [String]] {
                                    for key in errors.keys.makeIterator() {
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

    fileprivate func showActivityIndicator() {
        let section = tableView.numberOfSections - 1
        for view in tableView.cellForRow(at: IndexPath(row: 0, section: section))!.contentView.subviews {
            if view.isKind(of: UIActivityIndicatorView.self) {
                (view as! UIActivityIndicatorView).startAnimating()
            } else if view.isKind(of: UILabel.self) {
                view.alpha = 0.0
            }
        }
    }

    fileprivate func hideActivityIndicator() {
        let section = tableView.numberOfSections - 1
        for view in tableView.cellForRow(at: IndexPath(row: 0, section: section))!.contentView.subviews {
            if view.isKind(of: UIActivityIndicatorView.self) {
                (view as! UIActivityIndicatorView).stopAnimating()
            } else if view.isKind(of: UILabel.self) {
                view.alpha = 1.0
            }
        }
    }
}
