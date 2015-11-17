//
//  MenuViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol MenuViewControllerDelegate {
    func navigationControllerForMenuViewController(menuViewController: MenuViewController) -> UINavigationController!
}

class MenuViewController: UITableViewController, MenuHeaderViewDelegate {

    var delegate: MenuViewControllerDelegate!

    @IBOutlet private weak var menuHeaderView: MenuHeaderView!

    private var lastSectionIndex: Int {
        return tableView.numberOfSections - 1
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = Color.applicationDefaultBackgroundImageColor(view.frame)

        menuHeaderView.delegate = self

        alignSections()
    }

    // MARK: UITableView Delegate Functions

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedCell = tableView.cellForRowAtIndexPath(indexPath)!
        let reuseIdentifier = selectedCell.reuseIdentifier ?? ""

        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        switch reuseIdentifier {
        case "RouteCell":
            let storyboardName = reuseIdentifier.replaceString("Cell", withString: "")
            segueToInitialViewControllerInStoryboard(storyboardName)
        case "RouteHistoryCell":
            let storyboardName = reuseIdentifier.replaceString("Cell", withString: "")
            segueToInitialViewControllerInStoryboard(storyboardName)
        case "WorkOrderHistoryCell":
            let storyboardName = reuseIdentifier.replaceString("Cell", withString: "")
            segueToInitialViewControllerInStoryboard(storyboardName)
        case "LegalCell":
            let webViewController = UIStoryboard("Main").instantiateViewControllerWithIdentifier("WebViewController") as! WebViewController
            webViewController.url = NSURL(string: "https://provide.services/#/legal")
            NSNotificationCenter.defaultCenter().postNotificationName("MenuContainerShouldReset")
            delegate?.navigationControllerForMenuViewController(self).pushViewController(webViewController, animated: true)
        case "LogoutCell":
            NSNotificationCenter.defaultCenter().postNotificationName("MenuContainerShouldReset")
            NSNotificationCenter.defaultCenter().postNotificationName("ApplicationUserLoggedOut")

            ApiService.sharedService().logout(
                { statusCode, _ in
                    assert(statusCode == 204)
                    log("Logout Successful")
                },
                onError: { error, _, _ in
                    logWarn("Logout attempt failed; " + error.localizedDescription)
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
        if section == lastSectionIndex {
            return VersionHelper.fullVersion()
        } else {
            return nil
        }
    }

    // MARK: MenuHeaderViewDelegate

    func navigationViewControllerForMenuHeaderView(view: MenuHeaderView) -> UINavigationController! {
        if let delegate = delegate {
            return delegate.navigationControllerForMenuViewController(self)
        }

        return navigationController
    }

    // MARK: Private Methods

    private func alignSections() {
        // Position the 2nd section to line up flush with the bottom of the view
        let totalCellCount = tableView.numberOfRowsInSection(0) + tableView.numberOfRowsInSection(1) + tableView.numberOfRowsInSection(2)
        //let rowHeight = tableView[0].bounds.height // height of first cell
        let totalCellHeight = CGFloat(totalCellCount) * 50.0
        let versionNumberHeight: CGFloat = 38
        var tableHeaderViewHeight: CGFloat = 0
        if let tableHeaderView = tableView.tableHeaderView {
            tableHeaderViewHeight = tableHeaderView.bounds.height
        }
        let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.height
        let remainingSpace = view.bounds.height - (statusBarHeight + tableHeaderViewHeight + totalCellHeight + versionNumberHeight)
        tableView.sectionFooterHeight = remainingSpace / CGFloat(tableView.numberOfSections - 1)
    }

    private func segueToInitialViewControllerInStoryboard(storyboardName: String) {
        let storyboardPath = NSBundle.mainBundle().pathForResource(storyboardName, ofType: "storyboardc")
        if storyboardPath != nil {
            let initialViewController = UIStoryboard(storyboardName).instantiateInitialViewController()
            delegate?.navigationControllerForMenuViewController(self).pushViewController(initialViewController!, animated: true)
        } else {
            NSNotificationCenter.defaultCenter().postNotificationName("SegueTo\(storyboardName)Storyboard", object: self)
            NSNotificationCenter.defaultCenter().postNotificationName("MenuContainerShouldReset")
        }
    }
}
