//
//  WorkOrderProductCreationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/20/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

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

    private func populateTextFields() {
        if let workOrderProduct = workOrderProduct {
            if workOrderProduct.quantity == 0.0 {
                dispatch_after_delay(0.0) { [weak self] in
                    self?.quantityTextField?.becomeFirstResponder()
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
        if indexPath.section == 2 {
            if let workOrder = workOrder {
                let workOrderProduct = workOrder.workOrderProductForJobProduct(self.workOrderProduct.jobProduct)
                if let quantityString = quantityTextField?.text {
                    if let quantity = Double(quantityString) {
                        workOrderProduct.quantity = quantity
                    }
                }
                if let priceString = priceTextField?.text {
                    if priceString.length > 0 {
                        if let price = Double(priceString) {
                            workOrderProduct.price = price
                        }
                    }
                }

                workOrder.save(
                    onSuccess: { [weak self] statusCode, mappingResult in
                        if let s = self {
                            s.workOrderProductCreationViewControllerDelegate?.workOrderProductCreationViewController(s, didUpdateWorkOrderProduct: s.workOrderProduct)
                        }
                    },
                    onError: { error, statusCode, responseString in

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

    override func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == quantityTextField {
            if let quantity = textField.text {
                return quantity ~= "\\d+"
            }
        } else {
            // TODO-- validate price
            return true
        }
        return false
    }
    
}
