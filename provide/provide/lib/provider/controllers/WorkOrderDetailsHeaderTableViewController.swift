//
//  WorkOrderDetailsHeaderTableViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/28/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class WorkOrderDetailsHeaderTableViewController: UITableViewController {

    weak var workOrder: WorkOrder! {
        didSet {
            if let _ = workOrder {
                tableView.reloadData()
            }
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        print("selected cell \(cell)")
    }

    // MARK: UITableViewDataSource

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("workOrderDetailsHeaderTableViewCellReuseIdentifier") as! WorkOrderDetailsHeaderTableViewCell
        cell.workOrder = workOrder
        return cell
    }
}
