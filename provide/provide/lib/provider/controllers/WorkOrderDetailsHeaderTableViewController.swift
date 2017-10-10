//
//  WorkOrderDetailsHeaderTableViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/28/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol WorkOrderDetailsHeaderTableViewControllerDelegate: class {
    func workOrderDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController, shouldStartWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController, shouldCancelWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController, shouldCompleteWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController, shouldSubmitForApprovalWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController, shouldApproveWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController, shouldRejectWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewController(_ viewController: WorkOrderDetailsHeaderTableViewController, shouldRestartWorkOrder workOrder: WorkOrder)
}

class WorkOrderDetailsHeaderTableViewController: UITableViewController, WorkOrderDetailsHeaderTableViewCellDelegate {

    weak var workOrderDetailsHeaderTableViewControllerDelegate: WorkOrderDetailsHeaderTableViewControllerDelegate?

    weak var workOrder: WorkOrder! {
        didSet {
            if workOrder != nil {
                reloadTableView()
            }
        }
    }

    func reloadTableView() {
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // no-op
    }

    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(WorkOrderDetailsHeaderTableViewCell.self, for: indexPath)
        cell.workOrderDetailsHeaderTableViewCellDelegate = self
        cell.workOrder = workOrder
        return cell
    }

    // MARK: WorkOrderDetailsHeaderTableViewCellDelegate

    func workOrderDetailsHeaderTableViewCell(_ tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldStartWorkOrder workOrder: WorkOrder) {
        workOrderDetailsHeaderTableViewControllerDelegate?.workOrderDetailsHeaderTableViewController(self, shouldStartWorkOrder: workOrder)
    }

    func workOrderDetailsHeaderTableViewCell(_ tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldCancelWorkOrder workOrder: WorkOrder) {
        workOrderDetailsHeaderTableViewControllerDelegate?.workOrderDetailsHeaderTableViewController(self, shouldCancelWorkOrder: workOrder)
    }

    func workOrderDetailsHeaderTableViewCell(_ tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldCompleteWorkOrder workOrder: WorkOrder) {
        workOrderDetailsHeaderTableViewControllerDelegate?.workOrderDetailsHeaderTableViewController(self, shouldCompleteWorkOrder: workOrder)
    }

    func workOrderDetailsHeaderTableViewCell(_ tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldApproveWorkOrder workOrder: WorkOrder) {
        workOrderDetailsHeaderTableViewControllerDelegate?.workOrderDetailsHeaderTableViewController(self, shouldApproveWorkOrder: workOrder)
    }

    func workOrderDetailsHeaderTableViewCell(_ tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldSubmitForApprovalWorkOrder workOrder: WorkOrder) {
        workOrderDetailsHeaderTableViewControllerDelegate?.workOrderDetailsHeaderTableViewController(self, shouldSubmitForApprovalWorkOrder: workOrder)
    }

    func workOrderDetailsHeaderTableViewCell(_ tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldRejectWorkOrder workOrder: WorkOrder) {
        workOrderDetailsHeaderTableViewControllerDelegate?.workOrderDetailsHeaderTableViewController(self, shouldRejectWorkOrder: workOrder)
    }

    func workOrderDetailsHeaderTableViewCell(_ tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldRestartWorkOrder workOrder: WorkOrder) {
        workOrderDetailsHeaderTableViewControllerDelegate?.workOrderDetailsHeaderTableViewController(self, shouldRestartWorkOrder: workOrder)
    }
}
