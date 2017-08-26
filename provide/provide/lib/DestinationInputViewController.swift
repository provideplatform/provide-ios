//
//  DestinationInputViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/26/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import KTSwiftExtensions

class DestinationInputViewController: ViewController, UITextFieldDelegate {

    @IBOutlet fileprivate weak var destinationTextField: UITextField!
    
    fileprivate var initialFrame: CGRect!
    fileprivate var initialDestinationTextFieldFrame: CGRect!

    fileprivate var expanded = false {
        didSet {
            if expanded {
                initialFrame = view.frame
                initialDestinationTextFieldFrame = destinationTextField.frame

                destinationTextField.placeholder = ""
                
                UIView.animate(withDuration: 0.25, animations: { [weak self] in
                    self!.view.frame.origin.y = 0.0
                    self!.view.frame.size.width = self!.view.superview!.frame.width
                    self!.view.backgroundColor = .white
                    
                    self!.destinationTextField.frame.size.width = self!.view.frame.width
                    
                    self!.destinationTextField.becomeFirstResponder()
                })
            } else {
                destinationTextField.text = ""
                destinationTextField.placeholder = "Where to?"

                UIView.animate(withDuration: 0.25, animations: { [weak self] in
                    self!.view.frame = self!.initialFrame
                    self!.destinationTextField.frame = self!.initialDestinationTextFieldFrame
                    self!.view.backgroundColor = .clear
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

//    @available(iOS 2.0, *)
//    optional public func textFieldDidBeginEditing(_ textField: UITextField) // became first responder
//    
//    @available(iOS 2.0, *)
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
//    
//    @available(iOS 2.0, *)
//    optional public func textFieldShouldReturn(_ textField: UITextField) -> Bool // called when 'return' key pressed. return NO to ignore.
}