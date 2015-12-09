//
//  JobWizardViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol JobWizardViewControllerDelegate {
    func jobForJobWizardViewController(viewController: JobWizardViewController) -> Job!
}

class JobWizardViewController: UIViewController,
                               BlueprintViewControllerDelegate,
                               JobManagerViewControllerDelegate,
                               ManifestViewControllerDelegate,
                               ProviderPickerViewControllerDelegate,
                               PDTSimpleCalendarViewDelegate {

    var delegate: JobWizardViewControllerDelegate!

    var job: Job! {
        if  let delegate = delegate {
            return delegate.jobForJobWizardViewController(self)
        }
        return nil
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        let destinationViewController = segue.destinationViewController

        if let identifier = segue.identifier {
            if identifier == "JobWizardViewControllerEmbedSegue" {
                if destinationViewController.isKindOfClass(JobBlueprintsViewController) {
                    //(destinationViewController as! JobBlueprintsViewController).delegate = self

                } else if destinationViewController.isKindOfClass(ProviderPickerViewController) {
                    (destinationViewController as! ProviderPickerViewController).delegate = self

                } else if destinationViewController.isKindOfClass(ManifestViewController) {
                    (destinationViewController as! ManifestViewController).delegate = self

                } else if destinationViewController.isKindOfClass(UINavigationController) {
                    if let rootViewController = (destinationViewController as! UINavigationController).viewControllers.first {
                        if rootViewController.isKindOfClass(BlueprintViewController) {
                            (rootViewController as! BlueprintViewController).blueprintViewControllerDelegate = self
                        }
                    }

                } else if destinationViewController.isKindOfClass(JobManagerViewController) {
                    (destinationViewController as! JobManagerViewController).job = job

                } else if destinationViewController.isKindOfClass(JobReviewViewController) {
                    (destinationViewController as! JobReviewViewController).job = job
                    
                }
            }
        }
    }

    // MARK: BlueprintViewControllerDelegate
    func jobForBlueprintViewController(viewController: BlueprintViewController) -> Job! {
        return job
    }

    // MARK: JobManagerViewControllerDelegate

    // MARK: WorkOrderCreationViewControllerDelegate

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, numberOfSectionsInTableView tableView: UITableView) -> Int {
        return 1
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return indexPath.section == 0 ? 44.0 : 200.0
    }

    func workOrderCreationViewController(viewController: WorkOrderCreationViewController, tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : 1
    }

    func workOrderCreationViewController(workOrderCreationViewController: WorkOrderCreationViewController, tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let navigationController = workOrderCreationViewController.navigationController {
            var viewController: UIViewController!

            switch indexPath.row {
            case 0:
                PDTSimpleCalendarViewCell.appearance().circleSelectedColor = Color.darkBlueBackground()
                PDTSimpleCalendarViewCell.appearance().textDisabledColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)

                let calendarViewController = PDTSimpleCalendarViewController()
                calendarViewController.delegate = workOrderCreationViewController
                calendarViewController.weekdayHeaderEnabled = true
                calendarViewController.firstDate = NSDate()

                viewController = calendarViewController
            default:
                break
            }

            if let vc = viewController {
                navigationController.pushViewController(vc, animated: true)
            }
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    func jobManagerViewController(viewController: JobManagerViewController, cellForTableView tableView: UITableView, atIndexPath indexPath: NSIndexPath) -> UITableViewCell! {
        if indexPath.section > 0 {
            return nil
        }

        let job = viewController.job

        let cell = tableView.dequeueReusableCellWithIdentifier("nameValueTableViewCellReuseIdentifier") as! NameValueTableViewCell
        cell.enableEdgeToEdgeDividers()

        switch indexPath.row {
        case 0:
            let scheduledStartTime = "--"
//            if let humanReadableScheduledStartTime = job.humanReadableScheduledStartAtTimestamp {
//                scheduledStartTime = humanReadableScheduledStartTime
//            }

            cell.setName("\(job.status.uppercaseString)", value: scheduledStartTime)
            cell.backgroundView!.backgroundColor = job.statusColor
            cell.accessoryType = .DisclosureIndicator
        default:
            break
        }

        return cell
    }

    func jobManagerViewController(viewController: JobManagerViewController, didCreateExpense expense: Expense) {
        viewController.job.prependExpense(expense)
    }

    // MARK: ManifestViewControllerDelegate
    // TODO- implement optional methods

    // MARK: ProviderPickerViewControllerDelegate

    func providerPickerViewController(viewController: ProviderPickerViewController, didSelectProvider provider: Provider) {
        //        if !workOrder.hasProvider(provider) {
        //            let workOrderProvider = WorkOrderProvider()
        //            workOrderProvider.provider = provider
        //
        //            workOrder.workOrderProviders.append(workOrderProvider)
        //            isDirty = true
        //        }
        //        refreshRightBarButtonItems()
    }

    func providerPickerViewController(viewController: ProviderPickerViewController, didDeselectProvider provider: Provider) {
        //        workOrder.removeProvider(provider)
        //        isDirty = true
        //        refreshRightBarButtonItems()
    }

    func providerPickerViewControllerAllowsMultipleSelection(viewController: ProviderPickerViewController) -> Bool {
        return true
    }

    func selectedProvidersForPickerViewController(viewController: ProviderPickerViewController) -> [Provider] {
        if let job = job {
            if let supervisors = job.supervisors {
                return supervisors
            }
        }
        return [Provider]()
    }

    // MARK: PDTSimpleCalendarViewControllerDelegate

    func simpleCalendarViewController(controller: PDTSimpleCalendarViewController!, didSelectDate date: NSDate!) {
        //        workOrder.scheduledStartAt = date.format("yyyy-MM-dd'T'HH:mm:ssZZ")
        //        isDirty = true
        //        refreshRightBarButtonItems()
    }

    func simpleCalendarViewController(controller: PDTSimpleCalendarViewController!, isEnabledDate date: NSDate!) -> Bool {
        //        if let scheduledStartAtDate = workOrder.scheduledStartAtDate {
        //            return scheduledStartAtDate.atMidnight != date.atMidnight
        //        }
        return true
    }
}
