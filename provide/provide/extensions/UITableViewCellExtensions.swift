//
//  UITableViewCellExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

extension UITableViewCell {

    func enableEdgeToEdgeDividers() {
        layoutMargins = UIEdgeInsetsZero
        separatorInset = UIEdgeInsetsZero
        preservesSuperviewLayoutMargins = false
    }
}
