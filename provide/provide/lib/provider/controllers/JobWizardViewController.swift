//
//  JobWizardViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import PDTSimpleCalendar

protocol JobWizardViewControllerDelegate: NSObjectProtocol {
    func jobForJobWizardViewController(_ viewController: JobWizardViewController) -> Job!
    func floorplanImageForJobWizardViewController(_ viewController: JobWizardViewController) -> UIImage!
    func jobWizardViewController(_ viewController: JobWizardViewController, didSetScaleForFloorplanViewController: FloorplanViewController)
}

class JobWizardViewController: UINavigationController,
                               UINavigationControllerDelegate,
                               FloorplanViewControllerDelegate,
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

    weak var cachedFloorplanImage: UIImage! {
        if let jobWizardViewControllerDelegate = jobWizardViewControllerDelegate {
            if let cachedFloorplanImage = jobWizardViewControllerDelegate.floorplanImageForJobWizardViewController(self) {
                return cachedFloorplanImage
            }
        }
        return nil
    }

    fileprivate var reloadingJob = false

    fileprivate weak var pendingViewController: UIViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        refreshUI()
    }

    fileprivate func refreshUI() {
        refreshTitle()
        refreshLeftBarButtonItems()
        refreshRightBarButtonItems()
    }

    fileprivate func refreshTitle() {
        if let job = job {
            navigationItem.title = job.customer.contact.name
            navigationItem.titleView = nil
        }
    }

    fileprivate func refreshLeftBarButtonItems() {
        navigationItem.leftBarButtonItems = []
    }

    fileprivate func refreshRightBarButtonItems() {
        navigationItem.rightBarButtonItems = []
    }

    // MARK: UINavigationControllerDelegate

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {

    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if job == nil {
            pendingViewController = viewController
        } else {
            setupViewController(viewController)
        }
    }

    func setupViewController(_ viewController: UIViewController) {
        if viewController.isKind(of: JobFloorplansViewController.self) {
            //(viewController as! JobFloorplansViewController).delegate = self

        } else if viewController.isKind(of: JobTeamViewController.self) {
            (viewController as! JobTeamViewController).delegate = self

        } else if viewController.isKind(of: JobInventoryViewContoller.self) {
            (viewController as! JobInventoryViewContoller).delegate = self

        } else if viewController.isKind(of: FloorplanViewController.self) {
            (viewController as! FloorplanViewController).floorplanViewControllerDelegate = self

        } else if viewController.isKind(of: JobManagerViewController.self) {
            (viewController as! JobManagerViewController).job = job

        } else if viewController.isKind(of: JobReviewViewController.self) {
            (viewController as! JobReviewViewController).job = job
            
        }

        refreshUI()

        pendingViewController = nil
    }

    // MARK: FloorplanViewControllerDelegate

    func floorplanForFloorplanViewController(_ viewController: FloorplanViewController) -> Floorplan! {
        return nil
    }
    
    func floorplanImageForFloorplanViewController(_ viewController: FloorplanViewController) -> UIImage! {
        return cachedFloorplanImage
    }

    func jobForFloorplanViewController(_ viewController: FloorplanViewController) -> Job! {
        return job
    }

    func scaleCanBeSetByFloorplanViewController(_ viewController: FloorplanViewController) -> Bool {
        return false
    }

    func scaleWasSetForFloorplanViewController(_ viewController: FloorplanViewController) {

    }

    func newWorkOrderCanBeCreatedByFloorplanViewController(_ viewController: FloorplanViewController) -> Bool {
        if let job = job {
            return job.isCommercial && ["configuring", "in_progress"].index(of: job.status) != nil
        }
        return false
    }

    func areaSelectorIsAvailableForFloorplanViewController(_ viewController: FloorplanViewController) -> Bool {
        return false
    }

    func navigationControllerForFloorplanViewController(_ viewController: FloorplanViewController) -> UINavigationController! {
        return navigationController
    }

    func modeForFloorplanViewController(_ viewController: FloorplanViewController) -> FloorplanViewController.Mode! {
        return .workOrders
    }

    func floorplanViewControllerCanDropWorkOrderPin(_ viewController: FloorplanViewController) -> Bool {
        return false
    }

    func toolbarForFloorplanViewController(_ viewController: FloorplanViewController) -> FloorplanToolbar! {
        return nil
    }

    func showToolbarForFloorplanViewController(_ viewController: FloorplanViewController) {

    }

    func hideToolbarForFloorplanViewController(_ viewController: FloorplanViewController) {
        
    }
    
    // MARK: JobManagerViewControllerDelegate

    func jobManagerViewController(_ viewController: JobManagerViewController, numberOfSectionsInTableView tableView: UITableView) -> Int {
        return 1
    }

    func jobManagerViewController(_ viewController: JobManagerViewController, tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat {
        return (indexPath as NSIndexPath).section == 0 ? 44.0 : 200.0
    }

    func jobManagerViewController(_ viewController: JobManagerViewController, tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : 1
    }

    func jobManagerViewController(_ jobManagerViewController: JobManagerViewController, tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
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

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func jobManagerViewController(_ viewController: JobManagerViewController, cellForTableView tableView: UITableView, atIndexPath indexPath: IndexPath) -> UITableViewCell! {
        if (indexPath as NSIndexPath).section > 0 {
            return nil
        }

        let job = viewController.job

        let cell = tableView.dequeueReusableCell(withIdentifier: "nameValueTableViewCellReuseIdentifier") as! NameValueTableViewCell
        cell.enableEdgeToEdgeDividers()

        switch (indexPath as NSIndexPath).row {
        case 0:
            let scheduledStartTime = "--"
//            if let humanReadableScheduledStartTime = job.humanReadableScheduledStartAtTimestamp {
//                scheduledStartTime = humanReadableScheduledStartTime
//            }

            cell.setName("\(job?.status.uppercased())", value: scheduledStartTime)
            cell.backgroundView!.backgroundColor = job?.statusColor
            cell.accessoryType = .disclosureIndicator
        default:
            break
        }

        return cell
    }

    func jobManagerViewController(_ viewController: JobManagerViewController, didCreateExpense expense: Expense) {
        viewController.job.prependExpense(expense)
    }

    // MARK: JobInventoryViewControllerDelegate

    func jobForJobInventoryViewController(_ viewController: JobInventoryViewContoller) -> Job! {
        return job
    }

    // MARK: JobTeamViewControllerDelegate

    func jobForJobTeamViewController(_ viewController: JobTeamViewController) -> Job! {
        return job
    }

    deinit {
        let viewController = viewControllers.first
        if let jobFloorplansViewController = viewController as? JobFloorplansViewController {
            let _ = jobFloorplansViewController.teardown()
        } else if let floorplanViewController = viewController as? FloorplanViewController {
            let _ = floorplanViewController.teardown()
        }
    }
}
