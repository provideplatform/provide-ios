//
//  WorkOrderProductCreationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/20/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

@objc
protocol WorkOrderProductCreationViewControllerDelegate: NSObjectProtocol {
    optional func workOrderProductForWorkOrderProductCreationViewController(viewController: WorkOrderProductCreationViewController) -> WorkOrderProduct!
    func workOrderProductCreationViewController(viewController: WorkOrderProductCreationViewController, didUpdateWorkOrderProduct workOrderProduct: WorkOrderProduct)
}

class WorkOrderProductCreationViewController: ProductCreationViewController {

    weak var workOrderProductCreationViewControllerDelegate: WorkOrderProductCreationViewControllerDelegate! {
        didSet {
            if let workOrderProductCreationViewControllerDelegate = workOrderProductCreationViewControllerDelegate {
                if workOrderProduct == nil {
                    if let workOrderProduct = workOrderProductCreationViewControllerDelegate.workOrderProductForWorkOrderProductCreationViewController?(self) {
                        self.workOrderProduct = workOrderProduct
                    }
                }
            }
        }
    }

    var workOrder: WorkOrder!

    var workOrderProduct: WorkOrderProduct! {
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

        if let workOrder = workOrder {
            let workOrderProduct = workOrder.workOrderProductForJobProduct(self.workOrderProduct.jobProduct)
            if let quantityString = quantityTextField?.text {
                if let quantity = Double(quantityString) {
                    if quantity <= self.workOrderProduct.jobProduct.remainingQuantity {
                        workOrderProduct.quantity = quantity
                    } else {
                        quantityTextField?.text = ""
                        showToast("Quantity cannot exceed \(self.workOrderProduct.jobProduct.remainingQuantity)")
                        return
                    }
                }
            }
            if let priceString = priceTextField?.text {
                if priceString.length > 0 {
                    if let price = Double(priceString) {
                        workOrderProduct.price = price
                    }
                }
            }

            showActivityIndicator()

            workOrder.save(
                onSuccess: { statusCode, mappingResult in
                    self.workOrderProductCreationViewControllerDelegate?.workOrderProductCreationViewController(self, didUpdateWorkOrderProduct: self.workOrderProduct)
                },
                onError: { error, statusCode, responseString in
                    self.hideActivityIndicator()
                }
            )
        }
    }

    override func save(sender: UIButton) {
        save()
    }

    private func populateTextFields() {
        if let workOrderProduct = workOrderProduct {
            if workOrderProduct.quantity == 0.0 {
                dispatch_after_delay(0.0) { [weak self] in
                    self!.quantityTextField?.becomeFirstResponder()
                }
            } else {
                quantityTextField?.text = "\(workOrderProduct.quantity)"
            }

            if workOrderProduct.price > -1.0 {
                priceTextField?.text = "\(workOrderProduct.price)"
            } else if workOrderProduct.jobProduct.price > -1.0 {
                priceTextField?.text = "\(workOrderProduct.jobProduct.price)"
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
