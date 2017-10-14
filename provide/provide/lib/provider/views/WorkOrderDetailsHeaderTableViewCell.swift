//
//  WorkOrderDetailsHeaderTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 12/28/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import SWTableViewCell

protocol WorkOrderDetailsHeaderTableViewCellDelegate: class {
    func workOrderDetailsHeaderTableViewCell(_ tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldStartWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewCell(_ tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldCancelWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewCell(_ tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldCompleteWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewCell(_ tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldSubmitForApprovalWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewCell(_ tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldApproveWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewCell(_ tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldRejectWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewCell(_ tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldRestartWorkOrder workOrder: WorkOrder)
}

class WorkOrderDetailsHeaderTableViewCell: SWTableViewCell, SWTableViewCellDelegate, UITableViewDelegate, UITableViewDataSource {

    weak var workOrderDetailsHeaderTableViewCellDelegate: WorkOrderDetailsHeaderTableViewCellDelegate?

    weak var workOrder: WorkOrder! {
        didSet {
            if workOrder != nil {
                if Thread.isMainThread {
                    refresh()
                } else {
                    DispatchQueue.main.async {
                        self.refresh()
                    }
                }
            }
        }
    }

    private var isResponsibleSupervisor: Bool {
        return workOrder.supervisors.contains { $0.id == currentUser.id }
    }

    private var isResponsibleProvider: Bool {
        return workOrder.providers.contains { $0.userId == currentUser.id }
    }

    private var showsCancelButton: Bool {
        if workOrder == nil {
            return false
        }
        return !showsCompleteButton && isResponsibleSupervisor && workOrder.status != .completed && workOrder.status != .canceled && workOrder.status != .pendingApproval
    }

    private var showsApproveButton: Bool {
        if workOrder == nil {
            return false
        }
        return workOrder.status == .pendingApproval && isResponsibleSupervisor
    }

    private var showsRejectButton: Bool {
        if workOrder == nil {
            return false
        }
        return showsApproveButton
    }

    private var showsSubmitForApprovalButton: Bool {
        if workOrder == nil {
            return false
        }

        return workOrder.status == .inProgress && isResponsibleProvider
    }

    private var showsCompleteButton: Bool {
        if workOrder == nil {
            return false
        }
        return workOrder.status == .inProgress && !showsSubmitForApprovalButton && isResponsibleSupervisor
    }

    private var showsStartButton: Bool {
        if workOrder == nil {
            return false
        }
        return showsCancelButton && !showsSubmitForApprovalButton && [WorkOrder.Status.scheduled].index(of: workOrder.status) != nil
    }

    private var showsRestartButton: Bool {
        if workOrder == nil {
            return false
        }
        return isResponsibleProvider && [WorkOrder.Status.rejected].index(of: workOrder.status) != nil
    }

    @IBOutlet private weak var previewImageView: UIImageView! {
        didSet {
            if let previewImageView = previewImageView {
                previewImageView.superview?.backgroundColor = UIColor(red: 0.11, green: 0.29, blue: 0.565, alpha: 0.45)
                previewImageView.superview?.roundCorners(2.0)
            }
        }
    }

    @IBOutlet private weak var embeddedTableView: UITableView!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        backgroundColor = .clear
        contentView.backgroundColor = UIColor(red: 0.11, green: 0.29, blue: 0.565, alpha: 0.1)

        delegate = self

        refreshUtilityButtons()
    }

    private func refresh() {
        refreshUtilityButtons()
        embeddedTableView.reloadData()

        if let workOrder = workOrder {
            previewImageView?.contentMode = .scaleAspectFit
            previewImageView?.image = nil
            if let previewImage = workOrder.previewImage {
                previewImageView?.image = previewImage.scaledToWidth(previewImageView.width)
            }
        }
    }

    private func refreshUtilityButtons() {
        let leftUtilityButtons = NSMutableArray()
        let rightUtilityButtons = NSMutableArray()

        if showsCompleteButton {
            rightUtilityButtons.sw_addUtilityButton(with: Color.completedStatusColor(), title: "Complete")
        }

        if showsStartButton {
            rightUtilityButtons.sw_addUtilityButton(with: Color.inProgressStatusColor(), title: "Start")
        }

        if showsCancelButton {
            rightUtilityButtons.sw_addUtilityButton(with: Color.canceledStatusColor(), title: "Cancel")
        }

        if showsSubmitForApprovalButton {
            rightUtilityButtons.sw_addUtilityButton(with: Color.completedStatusColor(), title: "Submit for Approval") // FIXME-- attributed string title
        }

        if showsApproveButton {
            rightUtilityButtons.sw_addUtilityButton(with: Color.completedStatusColor(), title: "Approve")
        }

        if showsRejectButton {
            rightUtilityButtons.sw_addUtilityButton(with: Color.warningBackground(), title: "Reject")
        }

        if showsRestartButton {
            rightUtilityButtons.sw_addUtilityButton(with: Color.completedStatusColor(), title: "Continue to Fix")
        }

        setLeftUtilityButtons(leftUtilityButtons as [AnyObject], withButtonWidth: 0.0)
        setRightUtilityButtons(rightUtilityButtons as [AnyObject], withButtonWidth: 120.0)
    }

    // MARK: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let cell = tableView.cellForRow(at: indexPath), cell.accessoryType == .none {
            return nil
        }
        return indexPath
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(NameValueTableViewCell.self, for: indexPath)
        cell.enableEdgeToEdgeDividers()

        switch indexPath.row {
        case 0:
            cell.backgroundView!.backgroundColor = workOrder.statusColor

            cell.accessoryType = .none
            cell.setName(workOrder.status.rawValue.uppercased().replacingOccurrences(of: "_", with: " "), value: "")
        case 1:
            //            if workOrder.status == "en_route" || workOrder.status == "in_progress" {
            //                if let duration = self.workOrder.humanReadableDuration {
            //                    cell.setName("\(self.workOrder.status.uppercaseString)", value: duration)
            //                    cell.accessoryType = .None
            //                }
            //            } else {
            //                var scheduledStartTime = "--"
            //                if let humanReadableScheduledStartTime = workOrder.humanReadableScheduledStartAtTimestamp {
            //                    scheduledStartTime = humanReadableScheduledStartTime
            //                }
            //
            //                cell.setName("\(workOrder.status.uppercaseString)", value: scheduledStartTime)
            //                cell.accessoryType = .DisclosureIndicator
            //            }

            if workOrder.status == .scheduled || workOrder.status == .awaitingSchedule {
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.accessoryType = .none
            }

            var scheduledStartTime = "--"
            if let humanReadableScheduledStartTime = workOrder.humanReadableScheduledStartAtTimestamp {
                scheduledStartTime = humanReadableScheduledStartTime
            }

            cell.setName("START AT", value: scheduledStartTime)
        case 2:
            if workOrder.status == .scheduled || workOrder.status == .awaitingSchedule {
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.accessoryType = .none
            }

            var dueAtTime = "--"
            if let humanReadableDueAtTime = workOrder.humanReadableDueAtTimestamp {
                dueAtTime = humanReadableDueAtTime
            }

            cell.setName("DUE AT", value: dueAtTime)
        case 3:
            var specificProviders = ""
            let detailDisplayCount = 3
            var i = 0
            for provider in workOrder.providers {
                if i == detailDisplayCount {
                    break
                }
                specificProviders += ", \(provider.contact.name)"
                i += 1
            }
            let matches = KTRegex.match("^, ", input: specificProviders)
            if matches.count > 0 {
                let match = matches[0]
                let range = specificProviders.index(specificProviders.startIndex, offsetBy: match.range.length)..<specificProviders.endIndex
                specificProviders = specificProviders.substring(with: range)
            }
            var providers = "\(specificProviders)"
            if workOrder.providers.count > detailDisplayCount {
                providers += " and \(workOrder.providers.count - detailDisplayCount) other"
                if workOrder.providers.count - detailDisplayCount > 1 {
                    providers += "s"
                }
            } else if workOrder.providers.count == 0 {
                providers += "No one"
            }
            providers += " assigned"
            if workOrder.providers.count >= detailDisplayCount {
                cell.setName("CREW", value: providers, valueFontSize: isIPad() ? 12.0 : 10.0)
            } else {
                cell.setName("CREW", value: providers)
            }
            cell.accessoryType = .disclosureIndicator
        default:
            break
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }

    private func refreshInProgress() {
        if let tableView = embeddedTableView {
            var statusCell: NameValueTableViewCell!

            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? NameValueTableViewCell {
                statusCell = cell

                UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: {
                    statusCell.backgroundView?.backgroundColor = Color.inProgressStatusColor()

                    let alpha = statusCell.backgroundView?.alpha == 0.0 ? 0.9 : 0.0
                    statusCell.backgroundView?.alpha = CGFloat(alpha)

                    if let workOrder = self.workOrder, let duration = workOrder.humanReadableDuration {
                        statusCell.setName("\(workOrder.status.rawValue.uppercased())", value: duration)
                    }
                })
            }
        }
    }

    // MARK: SWTableViewCellDelegate

    func swipeableTableViewCell(_ cell: SWTableViewCell, didTriggerLeftUtilityButtonWith index: Int) {
        //  no-op
    }

    func swipeableTableViewCell(_ cell: SWTableViewCell, didTriggerRightUtilityButtonWith index: Int) {
        if index == 0 {
            if showsStartButton {
                workOrderDetailsHeaderTableViewCellDelegate?.workOrderDetailsHeaderTableViewCell(self, shouldStartWorkOrder: workOrder)
            } else if showsCancelButton {
                workOrderDetailsHeaderTableViewCellDelegate?.workOrderDetailsHeaderTableViewCell(self, shouldCancelWorkOrder: workOrder)
            } else if showsCompleteButton {
                workOrderDetailsHeaderTableViewCellDelegate?.workOrderDetailsHeaderTableViewCell(self, shouldCompleteWorkOrder: workOrder)
            } else if showsSubmitForApprovalButton {
                workOrderDetailsHeaderTableViewCellDelegate?.workOrderDetailsHeaderTableViewCell(self, shouldSubmitForApprovalWorkOrder: workOrder)
            } else if showsApproveButton {
                workOrderDetailsHeaderTableViewCellDelegate?.workOrderDetailsHeaderTableViewCell(self, shouldApproveWorkOrder: workOrder)
            } else if showsRestartButton {
                workOrderDetailsHeaderTableViewCellDelegate?.workOrderDetailsHeaderTableViewCell(self, shouldRestartWorkOrder: workOrder)
            }
        } else if index == 1 {
            if showsStartButton && showsCancelButton {
                workOrderDetailsHeaderTableViewCellDelegate?.workOrderDetailsHeaderTableViewCell(self, shouldCancelWorkOrder: workOrder)
            } else if showsRejectButton {
                workOrderDetailsHeaderTableViewCellDelegate?.workOrderDetailsHeaderTableViewCell(self, shouldRejectWorkOrder: workOrder)
            }
        }
    }

    func swipeableTableViewCell(_ cell: SWTableViewCell, canSwipeTo state: SWCellState) -> Bool {
        return true
    }

    func swipeableTableViewCellShouldHideUtilityButtons(onSwipe cell: SWTableViewCell!) -> Bool {
        return true
    }

    func swipeableTableViewCell(_ cell: SWTableViewCell, scrollingTo state: SWCellState) {
        // no-op
    }

    func swipeableTableViewCellDidEndScrolling(_ cell: SWTableViewCell!) {
        // no-op
    }
}
