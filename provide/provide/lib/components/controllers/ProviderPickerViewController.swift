//
//  ProviderPickerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 11/18/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol ProviderPickerViewControllerDelegate {
    func providerPickerViewController(viewController: ProviderPickerViewController, didSelectProvider provider: Provider)
    func providerPickerViewController(viewController: ProviderPickerViewController, didDeselectProvider provider: Provider)
    func providerPickerViewControllerAllowsMultipleSelection(viewController: ProviderPickerViewController) -> Bool
    func selectedProvidersForPickerViewController(viewController: ProviderPickerViewController) -> [Provider]
}

class ProviderPickerViewController: ViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    var delegate: ProviderPickerViewControllerDelegate! {
        didSet {
            if let delegate = delegate {
                for provider in delegate.selectedProvidersForPickerViewController(self) {
                    selectedProviders.append(provider)
                }
            }
        }
    }

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    @IBOutlet private weak var collectionView: UICollectionView! {
        didSet {
            if let collectionView = collectionView {
                collectionView.allowsMultipleSelection = delegate.providerPickerViewControllerAllowsMultipleSelection(self)
            }
        }
    }

    var providers: [Provider]! = [Provider]() {
        didSet {
            if let _ = providers {
                activityIndicatorView.stopAnimating()
            }

            collectionView.reloadData()
        }
    }

    private var selectedProviders = [Provider]()

    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicatorView.startAnimating()
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
