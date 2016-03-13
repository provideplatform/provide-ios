//
//  ExpenseEditorViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/8/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol ExpenseEditorViewControllerDelegate {
    func expenseEditorViewControllerBeganCreatingExpense(viewController: ExpenseEditorViewController)
    func expenseEditorViewController(viewController: ExpenseEditorViewController, didCreateExpense expense: Expense)
    func expenseEditorViewController(viewController: ExpenseEditorViewController, didFailToCreateExpenseWithStatusCode statusCode: Int)
}

class ExpenseEditorViewController: ExpenseViewController, UITextFieldDelegate {

    var delegate: ExpenseEditorViewControllerDelegate!

    @IBOutlet private weak var toolbar: UIToolbar! {
        didSet {
            if let toolbar = toolbar {
                toolbar.barTintColor = Color.applicationDefaultNavigationBarBackgroundColor()
            }
        }
    }

    @IBOutlet private weak var descriptionTextField: UITextField!
    @IBOutlet private weak var amountTextField: UITextField!

    @IBOutlet private weak var saveButtonItem: UIBarButtonItem! {
        didSet {
            if let saveButtonItem = saveButtonItem {
                saveButtonItem.target = self
                saveButtonItem.action = "save:"
                saveButtonItem.tintColor = Color.applicationDefaultBarButtonItemTintColor()
            }
        }
    }

    private var valid: Bool {
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

    func save(sender: UIBarButtonItem) {
        save()
    }

    func save() {
        if descriptionTextField.isFirstResponder() {
            descriptionTextField.resignFirstResponder()
        } else if amountTextField.isFirstResponder() {
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
                "amount": amount,
                "description": description,
                "incurred_at": incurredAt,
            ]

            self.delegate?.expenseEditorViewControllerBeganCreatingExpense(self)

            ApiService.sharedService().createExpense(expenseParams, forExpensableType: expense.expensableType,
                withExpensableId: String(expense.expensableId),
                onSuccess: { statusCode, mappingResult in
                    let receiptImage = self.expense.receiptImage
                    self.expense = mappingResult.firstObject as! Expense
                    if let receiptImage = receiptImage {
                        var params: [String : AnyObject] = [
                            "tags": ["photo", "receipt"],
                        ]

                        if let location = LocationService.sharedService().currentLocation {
                            params["latitude"] = location.coordinate.latitude
                            params["longitude"] = location.coordinate.longitude
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
                        self.delegate?.expenseEditorViewController(self, didCreateExpense: mappingResult.firstObject as! Expense)
                    }
                },
                onError: { error, statusCode, responseString in
                    self.delegate?.expenseEditorViewController(self, didFailToCreateExpenseWithStatusCode: statusCode)
                }
            )
        }
    }

    // MARK: UITextFieldDelegate

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if textField == amountTextField {
            if (string =~ "[.]") && textField.text!.contains(".") {
                return false
            }
            return string.length == 0 || (string =~ "[0-9.]")
        }
        return true
    }

    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if textField == amountTextField {
            textField.text = ""
        }
        return true
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
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

    func textFieldDidEndEditing(textField: UITextField) {
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
