//
//  ExpenseEditorViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/8/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

protocol ExpenseEditorViewControllerDelegate {
    func expenseEditorViewControllerBeganCreatingExpense(_ viewController: ExpenseEditorViewController)
    func expenseEditorViewController(_ viewController: ExpenseEditorViewController, didCreateExpense expense: Expense)
    func expenseEditorViewController(_ viewController: ExpenseEditorViewController, didFailToCreateExpenseWithStatusCode statusCode: Int)
}

class ExpenseEditorViewController: ExpenseViewController, UITextFieldDelegate {

    var delegate: ExpenseEditorViewControllerDelegate!

    @IBOutlet fileprivate weak var toolbar: UIToolbar! {
        didSet {
            if let toolbar = toolbar {
                toolbar.barTintColor = Color.applicationDefaultNavigationBarBackgroundColor()
            }
        }
    }

    @IBOutlet fileprivate weak var descriptionTextField: UITextField!
    @IBOutlet fileprivate weak var amountTextField: UITextField!

    @IBOutlet fileprivate weak var saveButtonItem: UIBarButtonItem! {
        didSet {
            if let saveButtonItem = saveButtonItem {
                saveButtonItem.target = self
                saveButtonItem.action = #selector(ExpenseEditorViewController.save(_:))
                saveButtonItem.tintColor = Color.applicationDefaultBarButtonItemTintColor()
            }
        }
    }

    fileprivate var valid: Bool {
        if let expense = expense {
            return expense.amount > 0.0 && expense.desc != nil && expense.incurredAtDate != nil
        }
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        hideLabels()

        if let expense = expense {
            descriptionTextField?.text = expense.desc
            amountTextField?.text = "\(expense.amount)"

            if descriptionTextField?.text!.length == 0 {
                descriptionTextField?.becomeFirstResponder()
            } else if let amountText = amountTextField?.text {
                if amountText.length == 0 || Double(amountText)! == 0 {
                    amountTextField?.becomeFirstResponder()
                }
            }
        }
    }

    func save(_ sender: UIBarButtonItem) {
        save()
    }

    func save() {
        if descriptionTextField.isFirstResponder {
            descriptionTextField.resignFirstResponder()
        } else if amountTextField.isFirstResponder {
            amountTextField.resignFirstResponder()
        }

        if !valid {
            return
        }

        if expense.id == 0 {
            let amount = expense.amount
            let description = expense.desc
            let incurredAt = expense.incurredAtDate.format("yyyy-MM-dd'T'HH:mm:ssZZ")

            let expenseParams: [String : AnyObject] = [
                "amount": amount as AnyObject,
                "description": description as AnyObject,
                "incurred_at": incurredAt as AnyObject,
            ]

            self.delegate?.expenseEditorViewControllerBeganCreatingExpense(self)

            ApiService.sharedService().createExpense(expenseParams, forExpensableType: expense.expensableType,
                withExpensableId: String(expense.expensableId),
                onSuccess: { statusCode, mappingResult in
                    let receiptImage = self.expense.receiptImage
                    self.expense = mappingResult?.firstObject as! Expense
                    if let receiptImage = receiptImage {
                        let tags = ["photo", "receipt"]
                        var params: [String : AnyObject] = [
                            "tags": tags as AnyObject,
                        ]

                        if let location = LocationService.sharedService().currentLocation {
                            params["latitude"] = location.coordinate.latitude as AnyObject
                            params["longitude"] = location.coordinate.longitude as AnyObject
                        }

                        self.expense.attach(receiptImage, params: params,
                            onSuccess: { (statusCode, mappingResult) -> () in
                                self.delegate?.expenseEditorViewController(self, didCreateExpense: self.expense)
                            },
                            onError: { (error, statusCode, responseString) -> () in
                                self.delegate?.expenseEditorViewController(self, didCreateExpense: self.expense)
                            }
                        )
                    } else {
                        self.delegate?.expenseEditorViewController(self, didCreateExpense: mappingResult?.firstObject as! Expense)
                    }
                },
                onError: { error, statusCode, responseString in
                    self.delegate?.expenseEditorViewController(self, didFailToCreateExpenseWithStatusCode: statusCode)
                }
            )
        }
    }

    // MARK: UITextFieldDelegate

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == amountTextField {
            if (string =~ "[.]") && textField.text!.range(of: ".") != nil {
                return false
            }
            return string.length == 0 || (string =~ "[0-9.]")
        }
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == amountTextField {
            textField.text = ""
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == descriptionTextField {
            amountTextField.becomeFirstResponder()
            return false
        } else if textField == amountTextField {
            if let _ = Double(amountTextField.text!) {
                amountTextField.resignFirstResponder()
                save()
            } else {
                return false
            }
        }
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == descriptionTextField {
            expense.desc = textField.text
        } else if textField == amountTextField {
            let text = textField.text!
            if text.length > 0 {
                expense.amount = Double(text)!
            }
        }
    }
}
