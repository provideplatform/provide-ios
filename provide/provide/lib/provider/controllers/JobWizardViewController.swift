//
//  JobWizardViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol JobWizardViewControllerDelegate: NSObjectProtocol {
    func jobForJobWizardViewController(viewController: JobWizardViewController) -> Job!
    func blueprintImageForJobWizardViewController(viewController: JobWizardViewController) -> UIImage!
    func jobWizardViewController(viewController: JobWizardViewController, didSetScaleForBlueprintViewController: BlueprintViewController)
}

class JobWizardViewController: UINavigationController,
                               UINavigationControllerDelegate,
                               BlueprintViewControllerDelegate,
                               JobManagerViewControllerDelegate,
                               JobInventoryViewControllerDelegate,
                               JobTeamViewControllerDelegate,
                               ManifestViewControllerDelegate,
                               PDTSimpleCalendarViewDelegate {

    weak var jobWizardViewControllerDelegate: JobWizardViewControllerDelegate? {
        didSet {
            if let _ = jobWizardViewControllerDelegate {
                if let pendingViewController = pendingViewController {
                    setupViewController(pendingViewController)
                }
            }
        }
    }

    weak var job: Job! {
        if  let jobWizardViewControllerDelegate = jobWizardViewControllerDelegate {
            return jobWizardViewControllerDelegate.jobForJobWizardViewController(self)
        }
        return nil
    }

    weak var cachedBlueprintImage: UIImage! {
        if let jobWizardViewControllerDelegate = jobWizardViewControllerDelegate {
            if let cachedBlueprintImage = jobWizardViewControllerDelegate.blueprintImageForJobWizardViewController(self) {
                return cachedBlueprintImage
            }
        }
        return nil
    }

    private var reloadingJob = false

    private weak var pendingViewController: UIViewController!

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
        if job == nil {
            pendingViewController = viewController
        } else {
            setupViewController(viewController)
        }
    }

    func setupViewController(viewController: UIViewController) {
        if viewController.isKindOfClass(JobBlueprintsViewController) {
            //(viewController as! JobBlueprintsViewController).delegate = self

        } else if viewController.isKindOfClass(JobTeamViewController) {
            (viewController as! JobTeamViewController).delegate = self

        } else if viewController.isKindOfClass(JobInventoryViewContoller) {
            (viewController as! JobInventoryViewContoller).delegate = self

        } else if viewController.isKindOfClass(BlueprintViewController) {
            (viewController as! BlueprintViewController).blueprintViewControllerDelegate = self

        } else if viewController.isKindOfClass(JobManagerViewController) {
            (viewController as! JobManagerViewController).job = job

        } else if viewController.isKindOfClass(JobReviewViewController) {
            (viewController as! JobReviewViewController).job = job
            
        }

        refreshUI()

        pendingViewController = nil
    }

    // MARK: BlueprintViewControllerDelegate

    func blueprintForBlueprintViewController(viewController: BlueprintViewController) -> Attachment! {
        return job.blueprint
    }
    
    func blueprintImageForBlueprintViewController(viewController: BlueprintViewController) -> UIImage! {
        return cachedBlueprintImage
    }

    func jobForBlueprintViewController(viewController: BlueprintViewController) -> Job! {
        return job
    }

    func scaleCanBeSetByBlueprintViewController(viewController: BlueprintViewController) -> Bool {
        return false
    }

    func scaleWasSetForBlueprintViewController(viewController: BlueprintViewController) {

    }

    func newWorkOrderCanBeCreatedByBlueprintViewController(viewController: BlueprintViewController) -> Bool {
        if let job = job {
            return job.isCommercial && ["configuring", "in_progress"].indexOfObject(job.status) != nil
        }
        return false
    }

    func areaSelectorIsAvailableForBlueprintViewController(viewController: BlueprintViewController) -> Bool {
        return false
    }

    func navigationControllerForBlueprintViewController(viewController: BlueprintViewController) -> UINavigationController! {
        return navigationController
    }

    func modeForBlueprintViewController(viewController: BlueprintViewController) -> BlueprintViewController.Mode! {
        return .WorkOrders
    }

    func estimateForBlueprintViewController(viewController: BlueprintViewController) -> Estimate! {
        return nil
    }

    func blueprintViewControllerCanDropWorkOrderPin(viewController: BlueprintViewController) -> Bool {
        return false
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
//        if let navigationController = jobManagerViewController.navigationController {
//            var viewController: UIViewController!
//
//            switch indexPath.row {
//            default:
//                break
//            }
//
//            if let vc = viewController {
//                navigationController.pushViewController(vc, animated: true)
//            }
//        }

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

    // MARK: JobInventoryViewControllerDelegate

    func jobForJobInventoryViewController(viewController: JobInventoryViewContoller) -> Job! {
        return job
    }

    // MARK: JobTeamViewControllerDelegate

    func jobForJobTeamViewController(viewController: JobTeamViewController) -> Job! {
        return job
    }

    deinit {
        let viewController = viewControllers.first
        if let jobBlueprintsViewController = viewController as? JobBlueprintsViewController {
            jobBlueprintsViewController.teardown()
        } else if let blueprintViewController = viewController as? BlueprintViewController {
            blueprintViewController.teardown()
        }
    }
}
