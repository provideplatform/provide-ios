//
//  ProviderPickerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 11/18/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol ProviderPickerViewControllerDelegate {
    func queryParamsForProviderPickerViewController(viewController: ProviderPickerViewController) -> [String : AnyObject]!
    func providerPickerViewController(viewController: ProviderPickerViewController, didSelectProvider provider: Provider)
    func providerPickerViewController(viewController: ProviderPickerViewController, didDeselectProvider provider: Provider)
    func providerPickerViewControllerAllowsMultipleSelection(viewController: ProviderPickerViewController) -> Bool
    func providersForPickerViewController(viewController: ProviderPickerViewController) -> [Provider]
    func selectedProvidersForPickerViewController(viewController: ProviderPickerViewController) -> [Provider]
    optional func collectionViewScrollDirectionForPickerViewController(viewController: ProviderPickerViewController) -> UICollectionViewScrollDirection
    optional func providerPickerViewControllerCanRenderResults(viewController: ProviderPickerViewController) -> Bool
}

class ProviderPickerViewController: ViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    var delegate: ProviderPickerViewControllerDelegate! {
        didSet {
            if let delegate = delegate {
                if oldValue == nil {
                    if let _ = delegate.queryParamsForProviderPickerViewController(self) {
                        reset()
                    } else {
                        providers = [Provider]()
                        for provider in delegate.providersForPickerViewController(self) {
                            providers.append(provider)
                        }
                    }

                    selectedProviders = [Provider]()
                    for provider in delegate.selectedProvidersForPickerViewController(self) {
                        selectedProviders.append(provider)
                    }

                    reloadCollectionView()
                }
            }
        }
    }

    private var inFlightRequestOperation: RKObjectRequestOperation!

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    @IBOutlet private weak var collectionView: UICollectionView! {
        didSet {
            if let _ = collectionView {
                if let _ = delegate {
                    reloadCollectionView()
                }
            }
        }
    }

    private var refreshControl: UIRefreshControl!

    var providers = [Provider]() {
        didSet {
            if providers.count == 0 {
                selectedProviders = [Provider]()
            }

            reloadCollectionView()
        }
    }

    private var selectedProviders = [Provider]()

    private var page = 1
    private let rpp = 10
    private var lastProviderIndex = -1

    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicatorView?.startAnimating()
    }

    func showActivityIndicator() {
        activityIndicatorView?.startAnimating()
    }

    func reloadCollectionView() {
        if let collectionView = collectionView {
            if let scrollDirection = delegate?.collectionViewScrollDirectionForPickerViewController?(self) {
                (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).scrollDirection = scrollDirection
            }

            var canRender = true
            if let canRenderResults = delegate?.providerPickerViewControllerCanRenderResults?(self) {
                canRender = canRenderResults
            }

            if canRender {
                collectionView.allowsMultipleSelection = delegate.providerPickerViewControllerAllowsMultipleSelection(self)

                selectedProviders = [Provider]()
                for provider in delegate.selectedProvidersForPickerViewController(self) {
                    selectedProviders.append(provider)
                }

                activityIndicatorView?.stopAnimating()
                refreshControl?.endRefreshing()
                collectionView.reloadData()
            } else {
                dispatch_after_delay(0.0) {
                    self.reloadCollectionView()
                }
            }
        }
    }

    private func setupPullToRefresh() {
        activityIndicatorView?.stopAnimating()

        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "reset", forControlEvents: .ValueChanged)

        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = true
    }

    func reset() {
        if refreshControl == nil {
            setupPullToRefresh()
        }

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

            if let defaultCompanyId = ApiService.sharedService().defaultCompanyId {
                params["company_id"] = defaultCompanyId
            }

            if let inFlightRequestOperation = inFlightRequestOperation {
                inFlightRequestOperation.cancel()
            }

            inFlightRequestOperation = ApiService.sharedService().fetchProviders(params,
                onSuccess: { statusCode, mappingResult in
                    self.inFlightRequestOperation = nil
                    let fetchedProviders = mappingResult.array() as! [Provider]
                    if self.page == 1 {
                        self.providers = [Provider]()
                    }
                    self.providers += fetchedProviders

                    self.reloadCollectionView()
                },
                onError: { error, statusCode, responseString in
                    self.inFlightRequestOperation = nil
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
