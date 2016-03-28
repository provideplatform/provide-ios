//
//  WorkOrderDetailsHeaderTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 12/28/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol WorkOrderDetailsHeaderTableViewCellDelegate {
    func workOrderCreationViewControllerForDetailsHeaderTableViewCell(tableViewCell: WorkOrderDetailsHeaderTableViewCell) -> WorkOrderCreationViewController!
    func workOrderDetailsHeaderTableViewCell(tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldStartWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewCell(tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldCancelWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewCell(tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldCompleteWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewCell(tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldSubmitForApprovalWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewCell(tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldApproveWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewCell(tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldRejectWorkOrder workOrder: WorkOrder)
    func workOrderDetailsHeaderTableViewCell(tableViewCell: WorkOrderDetailsHeaderTableViewCell, shouldRestartWorkOrder workOrder: WorkOrder)
}

class WorkOrderDetailsHeaderTableViewCell: SWTableViewCell, SWTableViewCellDelegate, UITableViewDelegate, UITableViewDataSource {

    var workOrderDetailsHeaderTableViewCellDelegate: WorkOrderDetailsHeaderTableViewCellDelegate!

    weak var workOrder: WorkOrder! {
        didSet {
            if let _ = workOrder {
                refresh()

                if let status = workOrder.status {
                    if status == "in_progress" || status == "en_route" {
                        if let timer = timer {
                            timer.invalidate()
                            self.timer = nil
                        }

                        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(WorkOrderDetailsHeaderTableViewCell.refreshInProgress), userInfo: nil, repeats: true)
                    }
                } else {
                    if let timer = timer {
                        timer.invalidate()
                        self.timer = nil
                    }
                }
            }
        }
    }

    private var timer: NSTimer!

    private var isResponsibleSupervisor: Bool {
        let user = currentUser()
        if let supervisors = workOrder.supervisors {
            for supervisor in supervisors {
                if supervisor.id == user.id {
                    return true
                }
            }
        }
        if workOrder.jobId > 0 {
            if let job = JobService.sharedService().jobWithId(workOrder.jobId) {
                if let supervisors = job.supervisors {
                    for provider in supervisors {
                        if provider.userId == user.id {
                            return true
                        }
                    }
                }
            }
        }

        return false
    }

    private var isResponsibleProvider: Bool {
        let user = currentUser()
        for provider in workOrder.providers {
            if provider.userId == user.id {
                return true
            }
        }
        return false
    }

    private var showsCancelButton: Bool {
        if workOrder == nil {
            return false
        }
        return !showsCompleteButton && isResponsibleSupervisor && workOrder.status != "completed" && workOrder.status != "canceled" && workOrder.status != "abandoned" && workOrder.status != "pending_approval"
    }

    private var showsApproveButton: Bool {
        if workOrder == nil {
            return false
        }
        return workOrder.status == "pending_approval" && isResponsibleSupervisor
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

        return workOrder.status == "in_progress" && isResponsibleProvider
    }

    private var showsCompleteButton: Bool {
        if workOrder == nil {
            return false
        }
        return workOrder.status == "in_progress" && !showsSubmitForApprovalButton && isResponsibleSupervisor
    }

    private var showsStartButton: Bool {
        if workOrder == nil {
            return false
        }
        return showsCancelButton && !showsSubmitForApprovalButton && ["scheduled"].indexOfObject(workOrder.status) != nil
    }

    private var showsRestartButton: Bool {
        if workOrder == nil {
            return false
        }
        return isResponsibleProvider && ["rejected"].indexOfObject(workOrder.status) != nil
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

        backgroundColor = UIColor.clearColor()
        contentView.backgroundColor = UIColor(red: 0.11, green: 0.29, blue: 0.565, alpha: 0.1)

        delegate = self

        refreshUtilityButtons()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    private func refresh() {
        refreshUtilityButtons()
        embeddedTableView.reloadData()

        if let workOrder = workOrder {
            previewImageView?.contentMode = .ScaleAspectFit
            previewImageView?.image = nil
            if let previewImage = workOrder.previewImage {
                previewImageView?.image = previewImage.scaledToWidth(previewImageView.frame.width)
            }
        }
    }

    private func refreshUtilityButtons() {
        let leftUtilityButtons = NSMutableArray()
        let rightUtilityButtons = NSMutableArray()

        if showsCompleteButton {
            rightUtilityButtons.sw_addUtilityButtonWithColor(Color.completedStatusColor(), title: "Complete")
        }

        if showsStartButton {
            rightUtilityButtons.sw_addUtilityButtonWithColor(Color.inProgressStatusColor(), title: "Start")
        }

        if showsCancelButton {
            rightUtilityButtons.sw_addUtilityButtonWithColor(Color.canceledStatusColor(), title: "Cancel")
        }

        if showsSubmitForApprovalButton {
            rightUtilityButtons.sw_addUtilityButtonWithColor(Color.canceledStatusColor(), title: "Submit for Approval") // FIXME-- attributed string title
        }

        if showsApproveButton {
            rightUtilityButtons.sw_addUtilityButtonWithColor(Color.completedStatusColor(), title: "Approve")
        }

        if showsRejectButton {
            rightUtilityButtons.sw_addUtilityButtonWithColor(Color.warningBackground(), title: "Reject")
        }

        if showsRestartButton {
            rightUtilityButtons.sw_addUtilityButtonWithColor(Color.completedStatusColor(), title: "Continue to Fix")
        }

        setLeftUtilityButtons(leftUtilityButtons as [AnyObject], withButtonWidth: 0.0)
        setRightUtilityButtons(rightUtilityButtons as [AnyObject], withButtonWidth: 120.0)
    }

    // MARK: UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("nameValueTableViewCellReuseIdentifier") as! NameValueTableViewCell
        cell.enableEdgeToEdgeDividers()

        switch indexPath.row {
        case 0:
            cell.backgroundView!.backgroundColor = workOrder.statusColor

            if workOrder.status == "en_route" || workOrder.status == "in_progress" {
                if let duration = self.workOrder.humanReadableDuration {
                    cell.setName("\(self.workOrder.status.uppercaseString)", value: duration)
                    cell.accessoryType = .None
                }
            } else {
                var scheduledStartTime = "--"
                if let humanReadableScheduledStartTime = workOrder.humanReadableScheduledStartAtTimestamp {
                    scheduledStartTime = humanReadableScheduledStartTime
                }

                cell.setName("\(workOrder.status.uppercaseString)", value: scheduledStartTime)
                cell.accessoryType = .DisclosureIndicator
            }
        case 1:
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
            let matches = Regex.match("^, ", input: specificProviders)
            if matches.count > 0 {
                let match = matches[0]
                let range = Range<String.Index>(start: specificProviders.startIndex.advancedBy(match.range.length), end: specificProviders.endIndex)
                specificProviders = specificProviders.substringWithRange(range)
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
            cell.accessoryType = .DisclosureIndicator

        default:
            break
        }

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let workOrderCreationViewController = workOrderDetailsHeaderTableViewCellDelegate?.workOrderCreationViewControllerForDetailsHeaderTableViewCell(self) {
            if let navigationController = workOrderCreationViewController.navigationController {
                var viewController: UIViewController!

                switch indexPath.row {
                case 0:
                    PDTSimpleCalendarViewCell.appearance().circleSelectedColor = Color.darkBlueBackground()
                    PDTSimpleCalendarViewCell.appearance().textDisabledColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)

                    let calendarViewController = CalendarViewController()
                    calendarViewController.delegate = workOrderCreationViewController
                    calendarViewController.weekdayHeaderEnabled = true
                    calendarViewController.firstDate = NSDate()

                    viewController = calendarViewController
                case 1:
                    viewController = UIStoryboard("WorkOrderCreation").instantiateViewControllerWithIdentifier("WorkOrderTeamViewController")
                    (viewController as! WorkOrderTeamViewController).delegate = workOrderCreationViewController
                    //            case 3:
                    //                viewController = UIStoryboard("WorkOrderCreation").instantiateViewControllerWithIdentifier("WorkOrderInventoryViewController")
                    //                (viewController as! WorkOrderInventoryViewController).delegate = workOrderCreationViewController
                    //            case 4:
                    //                viewController = UIStoryboard("Expenses").instantiateViewControllerWithIdentifier("ExpensesViewController")
                    //                (viewController as! ExpensesViewController).expenses = workOrderCreationViewController.workOrder.expenses
                    //                (viewController as! ExpensesViewController).delegate = self
                case 2:
                    viewController = UIStoryboard("CategoryPicker").instantiateViewControllerWithIdentifier("CategoryPickerViewController")
                    (viewController as! CategoryPickerViewController).delegate = workOrderCreationViewController
                    CategoryService.sharedService().fetch(companyId: workOrderCreationViewController.workOrder.companyId,
                        onCategoriesFetched: { categories in
                            (viewController as! CategoryPickerViewController).categories = categories

                            if let selectedCategory = workOrderCreationViewController.workOrder.category {
                                (viewController as! CategoryPickerViewController).selectedCategories = [selectedCategory]
                            }
                        }
                    )
                default:
                    break
                }
                
                if let vc = viewController {
                    navigationController.pushViewController(vc, animated: true)
                }
            }
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

    }

    func refreshInProgress() {
        if let tableView = embeddedTableView {
            var statusCell: NameValueTableViewCell!

            if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? NameValueTableViewCell {
                statusCell = cell

                UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseIn,
                    animations: {
                        statusCell.backgroundView!.backgroundColor = Color.completedStatusColor()

                        
                        let alpha = statusCell.backgroundView!.alpha == 0.0 ? 0.9 : 0.0
                        statusCell.backgroundView!.alpha = CGFloat(alpha)

                        if let duration = self.workOrder.humanReadableDuration {
                            statusCell.setName("\(self.workOrder.status.uppercaseString)", value: duration)
                        }
                    },
                    completion: { complete in

                    }
                )
            }
        }
    }

    // MARK: SWTableViewCellDelegate

    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerLeftUtilityButtonWithIndex index: Int) {
        //  no-op
    }

    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex index: Int) {
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

    func swipeableTableViewCell(cell: SWTableViewCell!, canSwipeToState state: SWCellState) -> Bool {
        return true
    }

    func swipeableTableViewCellShouldHideUtilityButtonsOnSwipe(cell: SWTableViewCell!) -> Bool {
        return true
    }

    func swipeableTableViewCell(cell: SWTableViewCell!, scrollingToState state: SWCellState) {
        // no-op
    }

    func swipeableTableViewCellDidEndScrolling(cell: SWTableViewCell!) {
        // no-op
    }

    deinit {
        timer?.invalidate()
    }
}
