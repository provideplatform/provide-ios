//
//  MenuViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

protocol MenuViewControllerDelegate {
    func navigationControllerForMenuViewController(_ menuViewController: MenuViewController) -> UINavigationController!
}

class MenuViewController: UITableViewController, MenuHeaderViewDelegate {

    var delegate: MenuViewControllerDelegate!

    @IBOutlet fileprivate weak var menuHeaderView: MenuHeaderView!

    fileprivate var storyboardPaths = [String : AnyObject!]()

    fileprivate var lastSectionIndex: Int {
        return tableView.numberOfSections - 1
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.backgroundColor = Color.darkBlueBackground()

        menuHeaderView.delegate = self

        alignSections()
    }

    // MARK: UITableViewDataSource

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuTableViewCellReuseIdentifier") as! MenuTableViewCell

        let menuItems = currentUser().menuItems
        if menuItems != nil && (indexPath as NSIndexPath).section == 0 {
            cell.menuItem = menuItems?[(indexPath as NSIndexPath).row]
        } else if (indexPath as NSIndexPath).section == 1 {
            var menuItem: MenuItem!
            switch (indexPath as NSIndexPath).row {
            case 0:
                menuItem = MenuItem(item: ["label": "Support", "url": "\(CurrentEnvironment.baseUrlString)/#/support"])
            case 1:
                menuItem = MenuItem(item: ["label": "Legal", "url": "\(CurrentEnvironment.baseUrlString)/#/legal"])
            case 2:
                menuItem = MenuItem(item: ["label": "Logout", "action": "logout"])
            default:
                break
            }

            if let menuItem = menuItem {
                cell.menuItem = menuItem
            }
        }

        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath)!
        //let reuseIdentifier = selectedCell.reuseIdentifier ?? ""

        tableView.deselectRow(at: indexPath, animated: true)

        if selectedCell.isKind(of: MenuTableViewCell.self) {
            if let menuItem = (selectedCell as! MenuTableViewCell).menuItem {
                if let selector = menuItem.selector {
                    if responds(to: selector) {
                        perform(selector)
                    }
                } else if let storyboard = menuItem.storyboard {
                    segueToInitialViewControllerInStoryboard(storyboard)
                } else if let url = menuItem.url {
                    let webViewController = UIStoryboard("Main").instantiateViewController(withIdentifier: "WebViewController") as! WebViewController
                    webViewController.url = url
                    NotificationCenter.default.postNotificationName("MenuContainerShouldReset")
                    delegate?.navigationControllerForMenuViewController(self).pushViewController(webViewController, animated: true)
                }
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if let menuItems = currentUser().menuItems {
                return menuItems.count
            }
            return 4
        case 1:
            return 3
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.enableEdgeToEdgeDividers()
        cell.backgroundColor = UIColor.clear
    }

    func alignSections() {
        var totalCellCount = 0
        var i = 0
        while i < tableView.numberOfSections {
            totalCellCount += tableView.numberOfRows(inSection: i)
            i += 1
        }
        //let rowHeight = tableView[0].bounds.height // height of first cell
        let totalCellHeight = CGFloat(totalCellCount) * 50.0
        let versionNumberHeight: CGFloat = 38
        var tableHeaderViewHeight: CGFloat = 0
        if let tableHeaderView = tableView.tableHeaderView {
            tableHeaderViewHeight = tableHeaderView.bounds.height
        }
        let statusBarHeight = UIApplication.shared.statusBarFrame.height
        let remainingSpace = view.bounds.height - (statusBarHeight + tableHeaderViewHeight + totalCellHeight + versionNumberHeight)
        tableView.sectionFooterHeight = remainingSpace / CGFloat(tableView.numberOfSections - 1)
    }

    func logout() {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .alert : .actionSheet
        let alertController = UIAlertController(title: "Confirmation", message: "Are you sure you want to logout?", preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(cancelAction)

        let logoutAction = UIAlertAction(title: "Logout", style: .destructive) { action in
            NotificationCenter.default.postNotificationName("MenuContainerShouldReset")
            NotificationCenter.default.postNotificationName("ApplicationUserLoggedOut")

            ApiService.sharedService().logout(
                { statusCode, _ in
                    assert(statusCode == 204)
                    log("Logout Successful")
                },
                onError: { error, _, _ in
                    logWarn("Logout attempt failed; " + error.localizedDescription)
                    //sender.userInteractionEnabled = true
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

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == lastSectionIndex {
            return KTVersionHelper.fullVersion()
        } else {
            return nil
        }
    }

    // MARK: MenuHeaderViewDelegate

    func navigationViewControllerForMenuHeaderView(_ view: MenuHeaderView) -> UINavigationController! {
        if let delegate = delegate {
            return delegate.navigationControllerForMenuViewController(self)
        }

        return navigationController
    }

    // MARK: Private Methods

    fileprivate func navigationControllerContains(_ clazz: AnyClass) -> Bool {
        for viewController in (delegate?.navigationControllerForMenuViewController(self)?.viewControllers)! {
            if viewController.isKind(of: clazz) {
                return true
            }
        }
        return false
    }

    fileprivate func segueToInitialViewControllerInStoryboard(_ storyboardName: String) {
        NotificationCenter.default.postNotificationName("MenuContainerShouldReset")

        var storyboardPath: String!
        if let _ = storyboardPaths.keys.index(of: storyboardName) {
            if storyboardPaths[storyboardName] != nil {
                storyboardPath = storyboardPaths[storyboardName] as? String
            }
        } else {
            storyboardPath = Bundle.main.path(forResource: storyboardName, ofType: "storyboardc")
            storyboardPaths.updateValue(storyboardPath as AnyObject!, forKey: storyboardName)
        }

        if storyboardPath != nil {
            var initialViewController = UIStoryboard(storyboardName).instantiateInitialViewController()!
            if initialViewController.isKind(of: UINavigationController.self) {
                initialViewController = (initialViewController as! UINavigationController).viewControllers[0]
            }
            if !navigationControllerContains(type(of: initialViewController)) {
                delegate?.navigationControllerForMenuViewController(self).pushViewController(initialViewController, animated: true)
            }
        } else {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "SegueTo\(storyboardName)Storyboard"), object: self)
        }
    }
}
