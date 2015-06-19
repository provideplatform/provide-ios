//
//  MenuViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class MenuViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = Color.menuBackgroundColor()

        alignSections()
    }

    // MARK: UITableView Delegate Functions

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedCell = tableView.cellForRowAtIndexPath(indexPath)!
        let reuseIdentifier = selectedCell.reuseIdentifier ?? ""

        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        switch reuseIdentifier {
        case "ManifestCell":
            let storyboardName = reuseIdentifier.replaceString("Cell", withString: "")
            segueToInitialViewControllerInStoryboard(storyboardName)
        case "LogoutCell":
            slidingViewController().dismissViewController(animated: true)
            ApiService.sharedService().logout(
                onSuccess: { statusCode, _ in
                    assert(statusCode == 204)
                    log("Logout Successful")
                },
                onError: { error, _, _ in
                    logError("Logout attempt failed; " + error.localizedDescription)
                    selectedCell.userInteractionEnabled = true
                }
            )
        default:
            break
        }
    }

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.enableEdgeToEdgeDividers()
        cell.backgroundColor = UIColor.clearColor()
    }

    // MARK: UITableView DataSource Functions

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return VersionHelper.fullVersion()
        } else {
            return nil
        }
    }

    // MARK: Private Methods

    private func alignSections() {
        // Position the 2nd section to line up flush with the bottom of the view
        let totalCellCount = tableView.numberOfRowsInSection(0) + tableView.numberOfRowsInSection(1)
        let rowHeight = tableView[0].bounds.height // height of first cell
        let totalCellHeight = CGFloat(totalCellCount) * rowHeight
        let versionNumberHeight: CGFloat = 38
        let remainingSpace = view.bounds.height - (totalCellHeight + tableView.tableHeaderView!.bounds.height + versionNumberHeight)
        tableView.sectionFooterHeight = remainingSpace
    }

    private func segueToInitialViewControllerInStoryboard(storyboardName: String) {
        if let storyboardPath = NSBundle.mainBundle().pathForResource(storyboardName, ofType: "storyboardc") {
            let initialViewController = UIStoryboard(storyboardName).instantiateInitialViewController() as! UIViewController
            let ecSlidingSegue = ECSlidingSegue(identifier: nil, source: self, destination: initialViewController)
            ecSlidingSegue.perform()
        } else {
            NSNotificationCenter.defaultCenter().postNotificationName("SegueTo\(storyboardName)Storyboard", object: self)
            slidingViewController().resetTopViewAnimated(true)
        }
    }

}
