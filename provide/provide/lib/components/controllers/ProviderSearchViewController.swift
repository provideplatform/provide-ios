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
    func providerSearchViewController(_ viewController: ProviderSearchViewController, didSelectProvider provider: Provider)
    @objc optional func providersForProviderSearchViewController(_ viewController: ProviderSearchViewController) -> [Provider]!
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

    @IBOutlet fileprivate weak var searchBar: UISearchBar! {
        didSet {
            if let searchBar = searchBar {
                searchBar.isHidden = hidesSearchBar
            }
        }
    }

    fileprivate var queryString: String!

    fileprivate var reloadingProviders = false
    fileprivate var reloadingProvidersCount = false
    fileprivate var addingProvider = false
    fileprivate var removingProvider = false

    fileprivate var maximumSearchlessProvidersCount = 20
    fileprivate var totalProvidersCount = -1

    fileprivate var isInputAccessory = false {
        didSet {
            if isInputAccessory {
                hidesSearchBar = true
            }
        }
    }

    fileprivate var hidesSearchBar = false {
        didSet {
            if let searchBar = searchBar {
                searchBar.isHidden = hidesSearchBar
            }
        }
    }

    fileprivate var showsAllProviders: Bool {
        return totalProvidersCount == -1 || totalProvidersCount <= maximumSearchlessProvidersCount
    }

    fileprivate var renderQueryResults: Bool {
        return queryString != nil || showsAllProviders
    }

    fileprivate var queryResultsPickerViewController: ProviderPickerViewController!
    fileprivate var queryResultsPickerTableViewCell: UITableViewCell! {
        if let queryResultsPickerViewController = queryResultsPickerViewController {
            return resolveTableViewCellForEmbeddedViewController(queryResultsPickerViewController)
        }
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if hidesSearchBar {
            let rect = tableView.rectForHeader(inSection: 0)
            tableView.contentOffset = CGPoint(x: 0.0, y: rect.origin.y)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier! == "QueryResultsProviderPickerEmbedSegue" {
            queryResultsPickerViewController = segue.destination as! ProviderPickerViewController
            queryResultsPickerViewController.delegate = self
        }
    }

    fileprivate func resolveTableViewCellForEmbeddedViewController(_ viewController: UIViewController) -> UITableViewCell! {
        var tableViewCell: UITableViewCell!
        var view = viewController.view
        while tableViewCell == nil {
            if let v = view?.superview {
                view = v
                if v is UITableViewCell {
                    tableViewCell = v as! UITableViewCell
                }
            }
        }
        return tableViewCell
    }

    func setInputAccessoryMode(_ isInputAccessory: Bool = true) {
        self.isInputAccessory = isInputAccessory
    }

    func hideSearchBar(_ hidden: Bool = true) {
        hidesSearchBar = hidden
    }

    func query(_ query: String) {
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

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if isInputAccessory {
            return 0.0
        }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return super.tableView(tableView, titleForHeaderInSection: section)
    }

    // MARK: UISearchBarDelegate

    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return !showsAllProviders
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        query(searchText)
    }

    // MARK: ProviderPickerViewControllerDelegate

    func providersForPickerViewController(_ viewController: ProviderPickerViewController) -> [Provider] {
        if queryResultsPickerViewController != nil && viewController == queryResultsPickerViewController {
            if let providers = providerSearchViewControllerDelegate?.providersForProviderSearchViewController?(self) {
                return providers
            }
        }

        return [Provider]()
    }

    func providerPickerViewController(_ viewController: ProviderPickerViewController, didSelectProvider provider: Provider) {
        providerSearchViewControllerDelegate?.providerSearchViewController(self, didSelectProvider: provider)
    }

    func providerPickerViewController(_ viewController: ProviderPickerViewController, didDeselectProvider provider: Provider) {

    }

    func providerPickerViewControllerAllowsMultipleSelection(_ viewController: ProviderPickerViewController) -> Bool {
        return false
    }

    func providerPickerViewControllerCanRenderResults(_ viewController: ProviderPickerViewController) -> Bool {
        if queryResultsPickerViewController != nil && viewController == queryResultsPickerViewController {
            return true
        }
        return false
    }

    func selectedProvidersForPickerViewController(_ viewController: ProviderPickerViewController) -> [Provider] {
        return [Provider]()
    }

    func queryParamsForProviderPickerViewController(_ viewController: ProviderPickerViewController) -> [String : AnyObject]! {
        if let providers = providerSearchViewControllerDelegate?.providersForProviderSearchViewController?(self) {
            viewController.providers = providers
            return nil
        }

        if let queryResultsPickerViewController = queryResultsPickerViewController {
            if viewController == queryResultsPickerViewController {
                let user = currentUser()
                var defaultCompanyId: AnyObject
                if user.defaultCompanyId > 0 {
                    defaultCompanyId = user.defaultCompanyId as AnyObject
                } else {
                    defaultCompanyId = NSNull()
                }

                if let queryString = queryString {
                    return ["company_id": defaultCompanyId, "q": queryString as AnyObject]
                }
            }
        }
        return nil
    }

    func providerPickerViewController(_ viewController: ProviderPickerViewController, collectionView: UICollectionView, cellForItemAtIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PickerCollectionViewCell", for: indexPath) as! PickerCollectionViewCell
        let providers = viewController.providers

        if providers.count > (indexPath as NSIndexPath).row - 1 {
            let provider = providers[(indexPath as NSIndexPath).row]

            cell.isSelected = viewController.isSelected(provider)

            if cell.isSelected {
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition())
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

    func collectionViewScrollDirectionForPickerViewController(_ viewController: ProviderPickerViewController) -> UICollectionViewScrollDirection {
        return .horizontal
    }
}
