//
//  MenuViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

protocol MenuViewControllerDelegate: NSObjectProtocol {
    func navigationControllerForMenuViewController(_ menuViewController: MenuViewController) -> UINavigationController!
    func menuItemForMenuViewController(_ menuViewController: MenuViewController, at indexPath: IndexPath) -> MenuItem!
    func numberOfSectionsInMenuViewController(_ menuViewController: MenuViewController) -> Int
    func menuViewController(_ menuViewController: MenuViewController, numberOfRowsInSection section: Int) -> Int
}

class MenuViewController: UITableViewController, MenuHeaderViewDelegate {

    var delegate: MenuViewControllerDelegate! {
        didSet {
            if delegate != nil {
                tableView.reloadData()
            }
        }
    }

    @IBOutlet fileprivate weak var menuHeaderView: MenuHeaderView!

    fileprivate var storyboardPaths = [String: AnyObject!]()

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
        cell.menuItem = delegate.menuItemForMenuViewController(self, at: indexPath)
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
                    } else if let delegate = delegate {
                        if let tvc = delegate as? TopViewController {
                            if tvc.rootViewController.responds(to: selector) {
                                tvc.rootViewController.perform(selector)
                            }
                        }

                        if delegate.responds(to: selector) {
                            delegate.perform(selector)
                        }
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
        if let delegate = delegate {
            return delegate.numberOfSectionsInMenuViewController(self)
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let delegate = delegate {
            return delegate.menuViewController(self, numberOfRowsInSection: section)
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.enableEdgeToEdgeDividers()
        cell.backgroundColor = .clear
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
                }
            )
        }

        alertController.addAction(cancelAction)
        alertController.addAction(logoutAction)

        if let navigationController = self.navigationViewControllerForMenuHeaderView(self.menuHeaderView) {
            navigationController.present(alertController, animated: true)
        } else {
            present(alertController, animated: true)
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
        if storyboardPaths.keys.index(of: storyboardName) != nil {
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
