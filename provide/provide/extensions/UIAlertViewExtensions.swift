//
//  UIAlertViewExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

extension UIAlertView {
    
    class func showToast(message: String, dismissAfter delay: NSTimeInterval = 1.5) {
        let alertView = UIAlertView(title: nil, message: message, delegate: nil, cancelButtonTitle: nil)
        alertView.show()
        
        dispatch_after_delay(delay) {
            alertView.dismissWithClickedButtonIndex(0, animated: true)
        }
    }
    
    convenience init(title: String? = nil, message: String? = nil, cancelButtonTitle: String? = "OK") {
        self.init(title: title, message: message, delegate: nil, cancelButtonTitle: cancelButtonTitle)
    }
    
}
