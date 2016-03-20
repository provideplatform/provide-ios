//
//  WorkOrderDetailsHeaderTableViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/28/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol WorkOrderDetailsHeaderTableViewControllerDelegate {
    func workOrderCreationViewControllerForDetailsHeaderTableViewController(viewController: WorkOrderDetailsHeaderTableViewController) -> WorkOrderCreationViewController!
    func workOrderDetailsHeaderTableViewController(viewController: WorkOrderDetailsHeaderTableViewController, shouldStartWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewController(viewController: WorkOrderDetailsHeaderTableViewController, shouldCancelWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewController(viewController: WorkOrderDetailsHeaderTableViewController, shouldCompleteWorkOrder workOrder: WorkOrder)
}

class WorkOrderDetailsHeaderTableViewController: UITableViewController, WorkOrderDetailsHeaderTableViewCellDelegate {

    var workOrderDetailsHeaderTableViewControllerDelegate: WorkOrderDetailsHeaderTableViewControllerDelegate!

    weak var workOrder: WorkOrder! {
        didSet {
            if let _ = workOrder {
                reloadTableView()
            }
        }
    }

    func reloadTableView() {
        tableView.reloadData()
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // no-op
    }

    // MARK: UITableViewDataSource

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("workOrderDetailsHeaderTableViewCellReuseIdentifier") as! WorkOrderDetailsHeaderTableViewCell
        cell.workOrderDetailsHeaderTableViewCellDelegate = self
        cell.workOrder = workOrder
        return cell
    }

    // MARK: WorkOrderDetailsHeaderTableViewCellDelegate

    func workOrderCreationViewControllerForDetailsHeaderTableViewCell(tableViewCell: WorkOrderDetailsHeaderTableViewCell) -> WorkOrderCreationViewController! {
        return workOrderDetailsHeaderTableViewControllerDelegate?.workOrderCreationViewControllerForDetailsHeaderTableViewController(self)
    }

    func workOrderDetailsHeaderTableViewCell(tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldStartWorkOrder workOrder: WorkOrder) {
        workOrderDetailsHeaderTableViewControllerDelegate?.workOrderDetailsHeaderTableViewController(self, shouldStartWorkOrder: workOrder)
    }

    func workOrderDetailsHeaderTableViewCell(tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldCancelWorkOrder workOrder: WorkOrder) {
        workOrderDetailsHeaderTableViewControllerDelegate?.workOrderDetailsHeaderTableViewController(self, shouldCancelWorkOrder: workOrder)
    }

    func workOrderDetailsHeaderTableViewCell(tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldCompleteWorkOrder workOrder: WorkOrder) {
        workOrderDetailsHeaderTableViewControllerDelegate?.workOrderDetailsHeaderTableViewController(self, shouldCompleteWorkOrder: workOrder)
    }
}
