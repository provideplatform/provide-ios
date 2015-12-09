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

class JobWizardViewController: ViewController,
                               BlueprintViewControllerDelegate,
                               JobManagerViewControllerDelegate,
                               ManifestViewControllerDelegate,
                               ProviderPickerViewControllerDelegate,
                               PDTSimpleCalendarViewDelegate {

    var jobWizardViewControllerDelegate: JobWizardViewControllerDelegate!

    var job: Job! {
        if  let jobWizardViewControllerDelegate = jobWizardViewControllerDelegate {
            return jobWizardViewControllerDelegate.jobForJobWizardViewController(self)
        }
        return nil
    }

    private var reloadingJob = false

    override func viewDidLoad() {
        super.viewDidLoad()

        //delegate = self

        refreshUI()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        let viewController = segue.destinationViewController

        if let identifier = segue.identifier {
            if identifier == "JobWizardViewControllerEmbedSegue" {
                
                if viewController.isKindOfClass(JobBlueprintsViewController) {
                    //(viewController as! JobBlueprintsViewController).delegate = self

                } else if viewController.isKindOfClass(ProviderPickerViewController) {
                    (viewController as! ProviderPickerViewController).delegate = self

                } else if viewController.isKindOfClass(ManifestViewController) {
                    (viewController as! ManifestViewController).delegate = self

                } else if viewController.isKindOfClass(BlueprintViewController) {
                    (viewController as! BlueprintViewController).blueprintViewControllerDelegate = self

                } else if viewController.isKindOfClass(JobManagerViewController) {
                    (viewController as! JobManagerViewController).job = job

                } else if viewController.isKindOfClass(JobReviewViewController) {
                    (viewController as! JobReviewViewController).job = job
                    
                }
                
                refreshUI()
            }
        }


    }

    private func refreshUI() {
//        if let navigationController = navigationController {
//            if navigationController.viewControllers.count > 1 {
//                navigationController.setNavigationBarHidden(true, animated: false)
//            }
//        }
        refreshTitle()
        refreshLeftBarButtonItems()
        refreshRightBarButtonItems()
    }

    private func refreshTitle() {
        if let job = job {
            navigationItem.title = job.customer.contact.name
            navigationItem.titleView = nil
        }
    }

    private func refreshLeftBarButtonItems() {
        navigationItem.leftBarButtonItems = []
    }

    private func refreshRightBarButtonItems() {
        navigationItem.rightBarButtonItems = []
    }

    // MARK: UINavigationControllerDelegate

    func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
//        let isRootViewController = navigationController.viewControllers.count == 1 && navigationController.viewControllers.first! == viewController
//        if isRootViewController {
//            navigationController.setNavigationBarHidden(true, animated: false)
//            if let navigationController = navigationController.navigationController {
//                navigationController.setNavigationBarHidden(false, animated: false)
//            }
//        }

//        if viewController.isKindOfClass(UINavigationController) {
//            if let rootViewController = (viewController as! UINavigationController).viewControllers.first {
//                if rootViewController.isKindOfClass(BlueprintViewController) {
//                    navigationController.popViewControllerAnimated(false)
//                    navigationController.pushViewController(rootViewController, animated: false)
//                }
//            }
//
//        }
    }

    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        if viewController.isKindOfClass(JobBlueprintsViewController) {
            //(viewController as! JobBlueprintsViewController).delegate = self

        } else if viewController.isKindOfClass(ProviderPickerViewController) {
            (viewController as! ProviderPickerViewController).delegate = self

        } else if viewController.isKindOfClass(ManifestViewController) {
            (viewController as! ManifestViewController).delegate = self

        } else if viewController.isKindOfClass(BlueprintViewController) {
            (viewController as! BlueprintViewController).blueprintViewControllerDelegate = self

        } else if viewController.isKindOfClass(JobManagerViewController) {
            (viewController as! JobManagerViewController).job = job

        } else if viewController.isKindOfClass(JobReviewViewController) {
            (viewController as! JobReviewViewController).job = job

        }

        refreshUI()
    }

    // MARK: BlueprintViewControllerDelegate
    func jobForBlueprintViewController(viewController: BlueprintViewController) -> Job! {
        return job
    }

    func navigationControllerForBlueprintViewController(viewController: BlueprintViewController) -> UINavigationController! {
        return navigationController
    }

    // MARK: JobManagerViewControllerDelegate

    func jobManagerViewController(viewController: JobManagerViewController, numberOfSectionsInTableView tableView: UITableView) -> Int {
        return 1
    }

    func jobManagerViewController(viewController: JobManagerViewController, tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return indexPath.section == 0 ? 44.0 : 200.0
    }

    func jobManagerViewController(viewController: JobManagerViewController, tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : 1
    }

    func jobManagerViewController(jobManagerViewController: JobManagerViewController, tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let navigationController = jobManagerViewController.navigationController {
            var viewController: UIViewController!

            switch indexPath.row {
            case 0:
                PDTSimpleCalendarViewCell.appearance().circleSelectedColor = Color.darkBlueBackground()
                PDTSimpleCalendarViewCell.appearance().textDisabledColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.5)

                let calendarViewController = PDTSimpleCalendarViewController()
                calendarViewController.delegate = jobManagerViewController
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

    func navigationControllerForViewController(viewController: UIViewController) -> UINavigationController! {
        if let navigationController = navigationController {
            if let parentNavigationController = navigationController.navigationController {
                return parentNavigationController
            }
            return navigationController
        }
        return nil
    }

    func workOrderForManifestViewController(viewController: UIViewController) -> WorkOrder! {
        return nil
    }

    func segmentsForManifestViewController(viewController: UIViewController) -> [String]! {
        return ["JOB MANIFEST"]
    }

    func itemsForManifestViewController(viewController: UIViewController, forSegmentIndex segmentIndex: Int) -> [Product]! {
        if segmentIndex == 0 {
            // job manifest
            if let job = job {
                if let _ = job.materials {
                    return job.materials.map { $0.product }
                } else {
                    reloadJobForManifestViewController(viewController as! ManifestViewController)
                }
            } else {
                reloadJobForManifestViewController(viewController as! ManifestViewController)
            }
        } else if segmentIndex == 1 {

        }

        return [Product]()
    }

    private func reloadJobForManifestViewController(viewController: ManifestViewController) {
        if !reloadingJob {
            if let job = job {
                dispatch_async_main_queue {
                    viewController.showActivityIndicator()
                }

                reloadingJob = true

                job.reloadExpenses(
                    { (statusCode, mappingResult) -> () in
                        self.refreshUI()
                        viewController.reloadTableView()
                        self.reloadingJob = false
                    },
                    onError: { (error, statusCode, responseString) -> () in
                        self.refreshUI()
                        viewController.reloadTableView()
                        self.reloadingJob = false
                    }
                )
            }
        }
    }

    // MARK: ManifestViewControllerDelegate

//    override func workOrderForManifestViewController(viewController: UIViewController) -> WorkOrder! {
//        return workOrder
//    }
//
//    func segmentsForManifestViewController(viewController: UIViewController) -> [String]! {
//        return ["MATERIALS", "JOB MANIFEST"]
//    }
//
//    func itemsForManifestViewController(viewController: UIViewController, forSegmentIndex segmentIndex: Int) -> [Product]! {
//        if segmentIndex == 0 {
//            // work order manifest
//            return workOrder.materials.map { $0.jobProduct.product }
//        } else if segmentIndex == 1 {
//            // job manifest
//            if let job = workOrder.job {
//                if let _ = job.materials {
//                    return job.materials.map { $0.product }
//                } else {
//                    reloadWorkOrderJobForManifestViewController(viewController as! ManifestViewController)
//                }
//            } else {
//                reloadWorkOrderJobForManifestViewController(viewController as! ManifestViewController)
//            }
//        }
//
//        return [Product]()
//    }
//
//    private func reloadWorkOrderJobForManifestViewController(viewController: ManifestViewController) {
//        if !reloadingJob {
//            dispatch_async_main_queue {
//                viewController.showActivityIndicator()
//            }
//
//            reloadingJob = true
//
//            workOrder.reloadJob(
//                { (statusCode, mappingResult) -> () in
//                    self.refreshUI()
//                    viewController.reloadTableView()
//                    self.reloadingJob = false
//                },
//                onError: { (error, statusCode, responseString) -> () in
//                    self.refreshUI()
//                    viewController.reloadTableView()
//                    self.reloadingJob = false
//                }
//            )
//        }
//    }

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


}
