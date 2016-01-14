//
//  ProviderSearchViewController.swift
//  provide
//
//  Created by Kyle Thomas on 1/14/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol ProviderSearchViewControllerDelegate {
    func providerSearchViewController(viewController: ProviderSearchViewController, didSelectProvider provider: Provider)
    optional func providersForProviderSearchViewController(viewController: ProviderSearchViewController) -> [Provider]!
}

class ProviderSearchViewController: UITableViewController, UISearchBarDelegate, ProviderPickerViewControllerDelegate {

    var providerSearchViewControllerDelegate: ProviderSearchViewControllerDelegate! {
        didSet {
            if let providerSearchViewControllerDelegate = providerSearchViewControllerDelegate {
                if let providers = providerSearchViewControllerDelegate.providersForProviderSearchViewController?(self) {
                    maximumSearchlessProvidersCount = providers.count
                    tableView?.reloadData()
                }
            }
        }
    }

    @IBOutlet private weak var searchBar: UISearchBar! {
        didSet {
            if let searchBar = searchBar {
                searchBar.hidden = hidesSearchBar
            }
        }
    }

    private var queryString: String!

    private var reloadingProviders = false
    private var reloadingProvidersCount = false
    private var addingProvider = false
    private var removingProvider = false

    private var maximumSearchlessProvidersCount = 20
    private var totalProvidersCount = -1

    private var isInputAccessory = false {
        didSet {
            if isInputAccessory {
                hidesSearchBar = true
            }
        }
    }

    private var hidesSearchBar = false {
        didSet {
            if let searchBar = searchBar {
                searchBar.hidden = hidesSearchBar
            }
        }
    }

    private var showsAllProviders: Bool {
        return totalProvidersCount == -1 || totalProvidersCount <= maximumSearchlessProvidersCount
    }

    private var renderQueryResults: Bool {
        return queryString != nil || showsAllProviders
    }

    private var queryResultsPickerViewController: ProviderPickerViewController!
    private var queryResultsPickerTableViewCell: UITableViewCell! {
        if let queryResultsPickerViewController = queryResultsPickerViewController {
            return resolveTableViewCellForEmbeddedViewController(queryResultsPickerViewController)
        }
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if hidesSearchBar {
            let rect = tableView.rectForHeaderInSection(0)
            tableView.contentOffset = CGPoint(x: 0.0, y: rect.origin.y)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier! == "QueryResultsProviderPickerEmbedSegue" {
            queryResultsPickerViewController = segue.destinationViewController as! ProviderPickerViewController
            queryResultsPickerViewController.delegate = self
        }
    }

    private func resolveTableViewCellForEmbeddedViewController(viewController: UIViewController) -> UITableViewCell! {
        var tableViewCell: UITableViewCell!
        var view = viewController.view
        while tableViewCell == nil {
            view = view.superview!
            if view.isKindOfClass(UITableViewCell) {
                tableViewCell = view as! UITableViewCell
            }
        }
        return tableViewCell
    }

    func setInputAccessoryMode(isInputAccessory: Bool = true) {
        self.isInputAccessory = isInputAccessory
    }

    func hideSearchBar(hidden: Bool = true) {
        hidesSearchBar = hidden
    }

    func query(query: String) {
        queryString = query

        if queryString.replaceString(" ", withString: "").length == 0 {
            queryString = nil

            if let providers = providerSearchViewControllerDelegate?.providersForProviderSearchViewController?(self) {
                queryResultsPickerViewController?.providers = providers
            } else {
                queryResultsPickerViewController?.providers = [Provider]()
            }

            tableView.reloadData()
        } else {
            tableView.reloadData()
            queryResultsPickerViewController?.reset()
        }
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if isInputAccessory {
            return 0.0
        }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return super.tableView(tableView, titleForHeaderInSection: section)
    }

    // MARK: UISearchBarDelegate

    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool {
        return !showsAllProviders
    }

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        query(searchText)
    }

    // MARK: ProviderPickerViewControllerDelegate

    func providersForPickerViewController(viewController: ProviderPickerViewController) -> [Provider] {
        if queryResultsPickerViewController != nil && viewController == queryResultsPickerViewController {
            if let providers = providerSearchViewControllerDelegate?.providersForProviderSearchViewController?(self) {
                return providers
            }
        }

        return [Provider]()
    }

    func providerPickerViewController(viewController: ProviderPickerViewController, didSelectProvider provider: Provider) {
        providerSearchViewControllerDelegate?.providerSearchViewController(self, didSelectProvider: provider)
    }

    func providerPickerViewController(viewController: ProviderPickerViewController, didDeselectProvider provider: Provider) {

    }

    func providerPickerViewControllerAllowsMultipleSelection(viewController: ProviderPickerViewController) -> Bool {
        return false
    }

    func providerPickerViewControllerCanRenderResults(viewController: ProviderPickerViewController) -> Bool {
        if queryResultsPickerViewController != nil && viewController == queryResultsPickerViewController {
            return true
        }
        return false
    }

    func selectedProvidersForPickerViewController(viewController: ProviderPickerViewController) -> [Provider] {
        return [Provider]()
    }

    func queryParamsForProviderPickerViewController(viewController: ProviderPickerViewController) -> [String : AnyObject]! {
        if let providers = providerSearchViewControllerDelegate?.providersForProviderSearchViewController?(self) {
            viewController.providers = providers
            return nil
        }

        if let queryResultsPickerViewController = queryResultsPickerViewController {
            if viewController == queryResultsPickerViewController {
                let user = currentUser()
                let defaultCompanyId = user.defaultCompanyId
                if let queryString = queryString {
                    return ["company_id": defaultCompanyId > 0 ? defaultCompanyId : NSNull(), "q": queryString]
                }
            }
        }
        return nil
    }

    func providerPickerViewController(viewController: ProviderPickerViewController, collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PickerCollectionViewCell", forIndexPath: indexPath) as! PickerCollectionViewCell
        let providers = viewController.providers

        if providers.count > indexPath.row - 1 {
            let provider = providers[indexPath.row]

            cell.selected = viewController.isSelected(provider)

            if cell.selected {
                collectionView.selectItemAtIndexPath(indexPath, animated: true, scrollPosition: .None)
            }

            cell.name = provider.contact.name

            if let profileImageUrl = provider.profileImageUrl {
                cell.imageUrl = profileImageUrl
            } else {
                cell.renderInitials()
            }
        }

        return cell
    }

    func collectionViewScrollDirectionForPickerViewController(viewController: ProviderPickerViewController) -> UICollectionViewScrollDirection {
        return .Horizontal
    }
}
