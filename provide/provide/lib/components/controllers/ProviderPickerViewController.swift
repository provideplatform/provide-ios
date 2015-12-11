//
//  ProviderPickerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 11/18/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol ProviderPickerViewControllerDelegate {
    func queryParamsForProviderPickerViewController(viewController: ProviderPickerViewController) -> [String : AnyObject]!
    func providerPickerViewController(viewController: ProviderPickerViewController, didSelectProvider provider: Provider)
    func providerPickerViewController(viewController: ProviderPickerViewController, didDeselectProvider provider: Provider)
    func providerPickerViewControllerAllowsMultipleSelection(viewController: ProviderPickerViewController) -> Bool
    func providersForPickerViewController(viewController: ProviderPickerViewController) -> [Provider]
    func selectedProvidersForPickerViewController(viewController: ProviderPickerViewController) -> [Provider]
}

class ProviderPickerViewController: ViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    var delegate: ProviderPickerViewControllerDelegate! {
        didSet {
            if let delegate = delegate {
                if let _ = delegate.queryParamsForProviderPickerViewController(self) {
                    setupPullToRefresh()
                } else {
                    for provider in delegate.providersForPickerViewController(self) {
                        providers.append(provider)
                    }

                    for provider in delegate.selectedProvidersForPickerViewController(self) {
                        selectedProviders.append(provider)
                    }
                }

                collectionView?.allowsMultipleSelection = delegate.providerPickerViewControllerAllowsMultipleSelection(self)

                activityIndicatorView?.stopAnimating()
                collectionView?.reloadData()
            }
        }
    }

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    @IBOutlet private weak var collectionView: UICollectionView! {
        didSet {
            if let collectionView = collectionView {
                if let delegate = delegate {
                    collectionView.allowsMultipleSelection = delegate.providerPickerViewControllerAllowsMultipleSelection(self)
                }
            }
        }
    }

    private var refreshControl: UIRefreshControl!

    var providers = [Provider]() {
        didSet {
            activityIndicatorView?.stopAnimating()
            collectionView?.reloadData()
        }
    }

    private var selectedProviders = [Provider]()

    private var page = 1
    private let rpp = 10
    private var lastProviderIndex = -1

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func showActivityIndicator() {
        activityIndicatorView?.startAnimating()
    }

    private func setupPullToRefresh() {
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "reset", forControlEvents: .ValueChanged)

        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = true

        refresh()
    }

    func reset() {
        providers = [Provider]()
        page = 1
        lastProviderIndex = -1
        refresh()
    }

    func refresh() {
        if page == 1 {
            refreshControl?.beginRefreshing()
        }

        if var params = delegate.queryParamsForProviderPickerViewController(self) {
            params["page"] = page
            params["rpp"] = rpp

            ApiService.sharedService().fetchProviders(params,
                onSuccess: { statusCode, mappingResult in
                    let fetchedProviders = mappingResult.array() as! [Provider]
                    self.providers += fetchedProviders

                    self.collectionView.reloadData()
                    self.refreshControl.endRefreshing()
                },
                onError: { error, statusCode, responseString in
                    // TODO
                }
            )
        }
    }

    private func isSelected(provider: Provider) -> Bool {
        for p in selectedProviders {
            if p.id == provider.id {
                return true
            }
        }
        return false
    }

    // MARK - UICollectionViewDataSource

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return providers.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PickerCollectionViewCell", forIndexPath: indexPath) as! PickerCollectionViewCell

        if providers.count > indexPath.row - 1 {
            let provider = providers[indexPath.row]

            cell.selected = isSelected(provider)

            if cell.selected {
                collectionView.selectItemAtIndexPath(indexPath, animated: true, scrollPosition: .None)
            }

            cell.name = provider.contact.name

            if let profileImageUrl = provider.profileImageUrl {
                cell.imageUrl = profileImageUrl
            } else {
                cell.gravatarEmail = provider.contact.email
            }
        }

        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let provider = providers[indexPath.row]
        delegate?.providerPickerViewController(self, didSelectProvider: provider)
    }

    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let provider = providers[indexPath.row]
        delegate?.providerPickerViewController(self, didDeselectProvider: provider)
    }

    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    func collectionView(collectionView: UICollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
}
