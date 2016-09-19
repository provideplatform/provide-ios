//
//  ProviderPickerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 11/18/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import RestKit
import KTSwiftExtensions

@objc
protocol ProviderPickerViewControllerDelegate {
    func queryParamsForProviderPickerViewController(_ viewController: ProviderPickerViewController) -> [String : AnyObject]!
    func providerPickerViewController(_ viewController: ProviderPickerViewController, didSelectProvider provider: Provider)
    func providerPickerViewController(_ viewController: ProviderPickerViewController, didDeselectProvider provider: Provider)
    func providerPickerViewControllerAllowsMultipleSelection(_ viewController: ProviderPickerViewController) -> Bool
    func providersForPickerViewController(_ viewController: ProviderPickerViewController) -> [Provider]
    func selectedProvidersForPickerViewController(_ viewController: ProviderPickerViewController) -> [Provider]
    @objc optional func collectionViewScrollDirectionForPickerViewController(_ viewController: ProviderPickerViewController) -> UICollectionViewScrollDirection
    @objc optional func providerPickerViewControllerCanRenderResults(_ viewController: ProviderPickerViewController) -> Bool
    @objc optional func providerPickerViewController(_ viewController: ProviderPickerViewController, collectionView: UICollectionView, cellForItemAtIndexPath indexPath: IndexPath) -> UICollectionViewCell
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

    fileprivate var inFlightRequestOperation: RKObjectRequestOperation!

    @IBOutlet fileprivate weak var activityIndicatorView: UIActivityIndicatorView!

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            if let _ = collectionView {
                if let _ = delegate {
                    reloadCollectionView()
                }
            }
        }
    }

    fileprivate var refreshControl: UIRefreshControl!

    var providers = [Provider]() {
        didSet {
            if providers.count == 0 {
                selectedProviders = [Provider]()
            }

            reloadCollectionView()
        }
    }

    fileprivate var selectedProviders = [Provider]()

    fileprivate var page = 1
    fileprivate let rpp = 10
    fileprivate var lastProviderIndex = -1

    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicatorView?.startAnimating()
    }

    func showActivityIndicator() {
        activityIndicatorView?.startAnimating()
    }

    func reloadCollectionView() {
        if let collectionView = collectionView {
            let collectionViewFlowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout

            if let scrollDirection = delegate?.collectionViewScrollDirectionForPickerViewController?(self) {
                collectionViewFlowLayout.scrollDirection = scrollDirection
            }

            collectionViewFlowLayout.minimumInteritemSpacing = 0.0
            collectionViewFlowLayout.minimumLineSpacing = 0.0
            collectionViewFlowLayout.itemSize = CGSize(width: 100.0, height: 100.0)

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

    fileprivate func setupPullToRefresh() {
        activityIndicatorView?.stopAnimating()

        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ProviderPickerViewController.reset), for: .valueChanged)

        collectionView.addSubview(refreshControl)
        collectionView.alwaysBounceVertical = true
    }

    func reset() {
        if inFlightRequestOperation != nil {
            return
        }

        if refreshControl == nil {
            //setupPullToRefresh()
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
            params["page"] = page as AnyObject
            params["rpp"] = rpp as AnyObject

            if let defaultCompanyId = ApiService.sharedService().defaultCompanyId {
                params["company_id"] = defaultCompanyId as AnyObject
            }

            if let inFlightRequestOperation = inFlightRequestOperation {
                inFlightRequestOperation.cancel()
            }

            inFlightRequestOperation = ApiService.sharedService().fetchProviders(params,
                onSuccess: { statusCode, mappingResult in
                    self.inFlightRequestOperation = nil
                    let fetchedProviders = mappingResult?.array() as! [Provider]
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

    func isSelected(_ provider: Provider) -> Bool {
        for p in selectedProviders {
            if p.id == provider.id {
                return true
            }
        }
        return false
    }

    // MARK - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return providers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = delegate?.providerPickerViewController?(self, collectionView: collectionView, cellForItemAtIndexPath: indexPath) {
            return cell
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PickerCollectionViewCell", for: indexPath) as! PickerCollectionViewCell

        if providers.count > (indexPath as NSIndexPath).row - 1 {
            let provider = providers[(indexPath as NSIndexPath).row]

            cell.isSelected = isSelected(provider)

            if cell.isSelected {
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition())
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

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let provider = providers[(indexPath as NSIndexPath).row]
        delegate?.providerPickerViewController(self, didSelectProvider: provider)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let provider = providers[(indexPath as NSIndexPath).row]
        delegate?.providerPickerViewController(self, didDeselectProvider: provider)
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
}
