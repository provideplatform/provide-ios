//
//  UITableViewExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

extension UITableView {

    subscript(reuseIdentifier: String) -> UITableViewCell {
        return dequeueReusableCellWithIdentifier(reuseIdentifier)!
    }

    subscript(reuseIdentifier: String, indexPath: NSIndexPath) -> UITableViewCell {
        return dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath)
    }

    subscript(row: Int) -> UITableViewCell {
        return cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: 0))!
    }

    subscript(row: Int, section: Int) -> UITableViewCell {
        return cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: section))!
    }
}
