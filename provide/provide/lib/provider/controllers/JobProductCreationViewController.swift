//
//  JobProductCreationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/14/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol JobProductCreationViewControllerDelegate: NSObjectProtocol {
    optional func jobProductForJobProductCreationViewController(viewController: JobProductCreationViewController) -> JobProduct!
    func jobProductCreationViewController(viewController: JobProductCreationViewController, didUpdateJobProduct jobProduct: JobProduct)
}

class JobProductCreationViewController: ProductCreationViewController {

    weak var jobProductCreationViewControllerDelegate: JobProductCreationViewControllerDelegate! {
        didSet {
            if let jobProductCreationViewControllerDelegate = jobProductCreationViewControllerDelegate {
                if jobProduct == nil {
                    if let jobProduct = jobProductCreationViewControllerDelegate.jobProductForJobProductCreationViewController?(self) {
                        self.jobProduct = jobProduct
                    }
                }
            }
        }
    }

    var job: Job!

    var jobProduct: JobProduct! {
        didSet {
            populateTextFields()
        }
    }

    @IBOutlet private weak var quantityTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        populateTextFields()
    }

    override func save() {
        tableView.endEditing(true)

        if let job = job {
            let jobProduct = job.jobProductForProduct(self.jobProduct.product)
            if let quantityString = quantityTextField?.text {
                if let quantity = Double(quantityString) {
                    jobProduct.initialQuantity = quantity
                    jobProduct.remainingQuantity = quantity
                }
            }
            if let priceString = priceTextField?.text {
                if priceString.length > 0 {
                    if let price = Double(priceString) {
                        jobProduct.price = price
                    }
                }
            }

            job.save(
                onSuccess: { statusCode, mappingResult in
                    self.jobProductCreationViewControllerDelegate?.jobProductCreationViewController(self, didUpdateJobProduct: self.jobProduct)
                },
                onError: { error, statusCode, responseString in

                }
            )
        }
    }

    private func populateTextFields() {
        if let jobProduct = jobProduct {
            if jobProduct.initialQuantity == 0.0 {
                dispatch_after_delay(0.0) { [weak self] in
                    self!.quantityTextField?.becomeFirstResponder()
                }
            } else {
                quantityTextField?.text = "\(jobProduct.initialQuantity)"
            }

            if jobProduct.price > -1.0 {
                priceTextField?.text = "\(jobProduct.price)"
            } else if let price = jobProduct.product.price {
                if price > -1.0 {
                    priceTextField?.text = "\(price)"
                }
            }
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    // MARK: UITextFieldDelegate

    override func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == quantityTextField {
            if let quantity = textField.text {
                if quantity =~ "\\d+" {
                    textField.resignFirstResponder()
                    if priceTextField.canBecomeFirstResponder() {
                        priceTextField.becomeFirstResponder()
                    }
                    return true
                }
            }
        } else if textField == priceTextField {
            if let price = Double(textField.text!) {
                if price >= 0.0 {
                    textField.resignFirstResponder()
                    dispatch_after_delay(0.0) {
                        self.save()
                    }
                    return true
                }
            }
        }
        return false
    }
}
