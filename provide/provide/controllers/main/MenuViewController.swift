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

    private var storyboardPaths = [String : AnyObject!]()

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
        case "JobsCell":
            let storyboardName = reuseIdentifier.replaceString("Cell", withString: "")
            segueToInitialViewControllerInStoryboard(storyboardName)
        case "LegalCell":
            let webViewController = UIStoryboard("Main").instantiateViewControllerWithIdentifier("WebViewController") as! WebViewController
            webViewController.url = NSURL(string: "\(CurrentEnvironment.baseUrlString)/#/legal")
            NSNotificationCenter.defaultCenter().postNotificationName("MenuContainerShouldReset")
            delegate?.navigationControllerForMenuViewController(self).pushViewController(webViewController, animated: true)
        case "LogoutCell":
            logout(selectedCell)
        default:
            break
        }
    }

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.enableEdgeToEdgeDividers()
        cell.backgroundColor = UIColor.clearColor()
    }

    func alignSections() {
        var totalCellCount = 0
        var i = 0
        while i < tableView.numberOfSections {
            totalCellCount += tableView.numberOfRowsInSection(i++)
        }
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

    private func logout(sender: UITableViewCell) {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .Alert : .ActionSheet
        let alertController = UIAlertController(title: "Confirmation", message: "Are you sure you want to logout?", preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Cancel", style: .Default, handler: nil)
        alertController.addAction(cancelAction)

        let logoutAction = UIAlertAction(title: "Logout", style: .Destructive) { action in
            NSNotificationCenter.defaultCenter().postNotificationName("MenuContainerShouldReset")
            NSNotificationCenter.defaultCenter().postNotificationName("ApplicationUserLoggedOut")

            ApiService.sharedService().logout(
                { statusCode, _ in
                    assert(statusCode == 204)
                    log("Logout Successful")
                },
                onError: { error, _, _ in
                    logWarn("Logout attempt failed; " + error.localizedDescription)
                    sender.userInteractionEnabled = true
                }
            )
        }

        alertController.addAction(cancelAction)
        alertController.addAction(logoutAction)

        if let navigationController = self.navigationViewControllerForMenuHeaderView(self.menuHeaderView) {
            navigationController.presentViewController(alertController, animated: true)
        } else {
            presentViewController(alertController, animated: true)
        }
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

    private func navigationControllerContains(clazz: AnyClass) -> Bool {
        for viewController in (delegate?.navigationControllerForMenuViewController(self)?.viewControllers)! {
            if viewController.isKindOfClass(clazz) {
                return true
            }
        }
        return false
    }

    private func segueToInitialViewControllerInStoryboard(storyboardName: String) {
        NSNotificationCenter.defaultCenter().postNotificationName("MenuContainerShouldReset")

        var storyboardPath: String!
        if let _ = storyboardPaths.keys.indexOf(storyboardName) {
            if storyboardPaths[storyboardName] != nil {
                storyboardPath = storyboardPaths[storyboardName] as? String
            }
        } else {
            storyboardPath = NSBundle.mainBundle().pathForResource(storyboardName, ofType: "storyboardc")
            storyboardPaths.updateValue(storyboardPath, forKey: storyboardName)
        }

        if storyboardPath != nil {
            var initialViewController = UIStoryboard(storyboardName).instantiateInitialViewController()!
            if initialViewController.isKindOfClass(UINavigationController) {
                initialViewController = (initialViewController as! UINavigationController).viewControllers[0]
            }
            if !navigationControllerContains(initialViewController.dynamicType) {
                delegate?.navigationControllerForMenuViewController(self).pushViewController(initialViewController, animated: true)
            }
        } else {
            NSNotificationCenter.defaultCenter().postNotificationName("SegueTo\(storyboardName)Storyboard", object: self)
        }
    }
}
