//
//  DestinationInputViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/26/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import KTSwiftExtensions

class DestinationInputViewController: ViewController, UITextFieldDelegate {

    weak var destinationResultsViewController: DestinationResultsViewController!

    @IBOutlet fileprivate weak var destinationTextField: UITextField!
    
    fileprivate var initialFrame: CGRect!
    fileprivate var initialDestinationTextFieldFrame: CGRect!
    fileprivate var initialDestinationResultsViewFrame: CGRect!

    fileprivate var expanded = false {
        didSet {
            if expanded {
                initialFrame = view.frame
                initialDestinationTextFieldFrame = destinationTextField.frame
                initialDestinationResultsViewFrame = destinationResultsViewController?.view.frame

                destinationTextField.placeholder = ""
                
                UIView.animate(withDuration: 0.25, animations: { [weak self] in
                    self!.view.frame.origin.y = 0.0
                    self!.view.frame.size.width = self!.view.superview!.frame.width
                    self!.view.backgroundColor = .white
                    
                    self!.destinationTextField.frame.size.width = self!.view.frame.width
                    self!.destinationTextField.becomeFirstResponder()
                })

                UIView.animate(withDuration: 0.45, animations: { [weak self] in
                    self!.destinationResultsViewController.view.frame.origin.y = self!.view.frame.height
                    self!.destinationResultsViewController.view.frame.size.height = self!.view.superview!.frame.height - self!.view.frame.height
                })
            } else {
                if destinationTextField.isFirstResponder {
                    destinationTextField.resignFirstResponder()
                }

                destinationTextField.text = ""
                destinationTextField.placeholder = "Where to?"

                UIView.animate(withDuration: 0.25, animations: { [weak self] in
                    self!.view.frame = self!.initialFrame
                    self!.view.backgroundColor = .clear

                    self!.destinationResultsViewController.view.frame = self!.initialDestinationResultsViewFrame
                })
            }
        }
    }
    
    // MARK: UITextFieldDelegate

    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if !expanded {
            expanded = true
            return false
        }
        return true
    }

//    optional public func textFieldDidBeginEditing(_ textField: UITextField) // became first responder
//
//    optional public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool // return YES to allow editing to stop and to resign first responder status. NO to disallow the editing session to end
//    
//    @available(iOS 2.0, *)
//    optional public func textFieldDidEndEditing(_ textField: UITextField) // may be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called
//    
//    @available(iOS 10.0, *)
//    optional public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) // if implemented, called in place of textFieldDidEndEditing:
//    
//    
//    @available(iOS 2.0, *)
//    optional public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool // return NO to not change text
//    
//    
//    @available(iOS 2.0, *)
//    optional public func textFieldShouldClear(_ textField: UITextField) -> Bool // called when clear button pressed. return NO to ignore (no notifications)

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        expanded = false
        return true
    }
}
