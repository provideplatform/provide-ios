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
        return self.dequeueReusableCellWithIdentifier(reuseIdentifier) as! UITableViewCell
    }
    
    subscript(reuseIdentifier: String, indexPath: NSIndexPath) -> UITableViewCell {
        return self.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath) as! UITableViewCell
    }
    
    subscript(row: Int) -> UITableViewCell {
        return self.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: 0))!
    }
    
    subscript(row: Int, section: Int) -> UITableViewCell {
        return self.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: section))!
    }
    
}
