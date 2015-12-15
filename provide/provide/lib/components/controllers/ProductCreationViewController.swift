//
//  ProductCreationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/14/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol ProductCreationViewControllerDelegate {
    func productCreationViewController(viewController: ProductCreationViewController, didCreateProduct product: Product)
}

class ProductCreationViewController: UITableViewController, UITextFieldDelegate {

    var delegate: ProductCreationViewControllerDelegate!

    @IBOutlet private weak var nameTextField: UITextField!
    @IBOutlet private weak var gtinTextField: UITextField!
    @IBOutlet private weak var priceTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 3 {
            let user = currentUser()
            if user.defaultCompanyId > 0 {
                createProductWithCompanyId(user.defaultCompanyId)
            } else {
                print("WARNING: this user is associated with multiple companies as a provider so cannot attempt creation without user input")
            }
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == 3 {
            tableView.cellForRowAtIndexPath(indexPath)!.alpha = 0.8
        }
        return indexPath
    }

    override func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 3 {
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

    private func createProductWithCompanyId(companyId: Int) {
        let product = Product()
        product.companyId = companyId
        product.data = [String : AnyObject]()
        product.data["name"] = nameTextField?.text

        let productIsValid = product.companyId > 0 && product.name != nil && product.name!.length > 0

        if productIsValid {
            showActivityIndicator()

            product.save(
                onSuccess: { statusCode, mappingResult in
                    if statusCode == 201 {
                        self.hideActivityIndicator()
                        self.delegate?.productCreationViewController(self, didCreateProduct: mappingResult.firstObject as! Product)
                    }
                },
                onError: { error, statusCode, responseString in
                    self.hideActivityIndicator()
                }
            )
        } else {
            hideActivityIndicator()
        }
    }

    private func showActivityIndicator() {
        for view in tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 3))!.contentView.subviews {
            if view.isKindOfClass(UIActivityIndicatorView) {
                (view as! UIActivityIndicatorView).startAnimating()
            } else if view.isKindOfClass(UILabel) {
                view.alpha = 0.0
            }
        }
    }

    private func hideActivityIndicator() {
        for view in tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 3))!.contentView.subviews {
            if view.isKindOfClass(UIActivityIndicatorView) {
                (view as! UIActivityIndicatorView).stopAnimating()
            } else if view.isKindOfClass(UILabel) {
                view.alpha = 1.0
            }
        }
    }
}
