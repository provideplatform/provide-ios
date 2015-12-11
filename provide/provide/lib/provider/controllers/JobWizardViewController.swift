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

class JobWizardViewController: UINavigationController,
                               UINavigationControllerDelegate,
                               JobBlueprintsViewControllerDelegate,
                               BlueprintViewControllerDelegate,
                               JobManagerViewControllerDelegate,
                               JobTeamViewControllerDelegate,
                               ManifestViewControllerDelegate,
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

        delegate = self

        refreshUI()
    }

    private func refreshUI() {
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

    }

    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        if viewController.isKindOfClass(JobBlueprintsViewController) {
            (viewController as! JobBlueprintsViewController).delegate = self

        } else if viewController.isKindOfClass(JobTeamViewContoller) {
            (viewController as! JobTeamViewContoller).delegate = self

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

    // MARK: JobBlueprintsViewControllerDelegate

    func jobForJobBlueprintsViewController(viewController: JobBlueprintsViewController) -> Job! {
        return job
    }

    // MARK: BlueprintViewControllerDelegate

    func jobForBlueprintViewController(viewController: BlueprintViewController) -> Job! {
        return job
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

    func workOrderForManifestViewController(viewController: UIViewController) -> WorkOrder! {
        return nil
    }

    func segmentsForManifestViewController(viewController: UIViewController) -> [String]! {
        return ["JOB MANIFEST"]
    }

    func jobForManifestViewController(viewController: UIViewController) -> Job! {
        return job
    }

    func itemsForManifestViewController(viewController: UIViewController, forSegmentIndex segmentIndex: Int) -> [Product]! {
        let manifestViewController = viewController as! ManifestViewController
        return jobProductsForManifestViewController(manifestViewController, forSegmentIndex: segmentIndex).map({ $0.product })
    }

    func manifestViewController(viewController: UIViewController, tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell! {
        let cell = tableView.dequeueReusableCellWithIdentifier("jobProductTableViewCell") as! JobProductTableViewCell
        let manifestViewController = viewController as! ManifestViewController
        cell.jobProduct = jobProductsForManifestViewController(manifestViewController, forSegmentIndex: manifestViewController.selectedSegmentIndex)[indexPath.row]
        return cell
    }

    func manifestViewController(viewController: UIViewController, tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let manifestViewController = viewController as! ManifestViewController
        let jobProduct = jobProductsForManifestViewController(manifestViewController, forSegmentIndex: manifestViewController.selectedSegmentIndex)[indexPath.row]
        print("selected job product \(jobProduct)")
    }

    private func jobProductsForManifestViewController(viewController: ManifestViewController, forSegmentIndex segmentIndex: Int) -> [JobProduct] {
        if segmentIndex > -1 {
            // job manifest
            if segmentIndex == 0 {
                if let job = job {
                    if let _ = job.materials {
                        return job.materials
                    } else {
                        reloadJobForManifestViewController(viewController)
                    }
                } else {
                    reloadJobForManifestViewController(viewController)
                }
            } else if segmentIndex == 1 {
                // no-op
            }
        }

        return [JobProduct]()
    }

    private func reloadJobForManifestViewController(viewController: ManifestViewController) {
        if !reloadingJob {
            if let job = job {
                dispatch_async_main_queue {
                    viewController.showActivityIndicator()
                }

                reloadingJob = true

                job.reloadMaterials(
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

    // MARK: JobTeamViewControllerDelegate

    func jobForJobTeamViewController(viewController: JobTeamViewContoller) -> Job! {
        return job
    }
}
