//
//  ProviderPickerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 1/5/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol ProviderPickerViewControllerDelegate {
    func providerPickerViewController(viewController: ProviderPickerViewController, didSelectProvider provider: Provider)
}

class ProviderPickerViewController: ViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    var delegate: ProviderPickerViewControllerDelegate!

    @IBOutlet private weak var collectionView: UICollectionView!

    var providers: [Provider] = [Provider]() {
        didSet {
            collectionView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        //view.backgroundColor = UIColor.clearColor()
        view.alpha = 1

        //collectionView.backgroundColor = Colors.darkBlueBackground()
    }

    // MARK - UICollectionViewDataSource

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return providers.count
    }

    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PickerCollectionViewCell", forIndexPath: indexPath) as! PickerCollectionViewCell

        if providers.count >= indexPath.row {
            let provider = providers[indexPath.row]

            cell.name = provider.name
            cell.gravatarEmail = provider.contact.email

            cell.attachGestureRecognizers()
        }

        return cell
    }

    //optional func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int

    // The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
    //optional func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView

    // MARK - UICollectionViewDelegate

    // Methods for notification of selection/deselection and highlight/unhighlight events.
    // The sequence of calls leading to selection from a user touch is:
    //
    // (when the touch begins)
    // 1. -collectionView:shouldHighlightItemAtIndexPath:
    // 2. -collectionView:didHighlightItemAtIndexPath:
    //
    // (when the touch lifts)
    // 3. -collectionView:shouldSelectItemAtIndexPath: or -collectionView:shouldDeselectItemAtIndexPath:
    // 4. -collectionView:didSelectItemAtIndexPath: or -collectionView:didDeselectItemAtIndexPath:
    // 5. -collectionView:didUnhighlightItemAtIndexPath:

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let provider = providers[indexPath.row]
        delegate?.providerPickerViewController(self, didSelectProvider: provider)
    }

//    optional func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool
//    optional func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath)
//    optional func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath!
    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    func collectionView(collectionView: UICollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
//    optional func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
//    optional func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath)
//
//    @availability(iOS, introduced=8.0)
//    optional func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath)
//    @availability(iOS, introduced=8.0)
//    optional func collectionView(collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, atIndexPath indexPath: NSIndexPath)
//    optional func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath)
//    optional func collectionView(collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, atIndexPath indexPath: NSIndexPath)
//
//    // These methods provide support for copy/paste actions on cells.
//    // All three should be implemented if any are.
//    optional func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool
//    optional func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject!) -> Bool
//    optional func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject!)
//
//    // support for custom transition layout
//    optional func collectionView(collectionView: UICollectionView, transitionLayoutForOldLayout fromLayout: UICollectionViewLayout, newLayout toLayout: UICollectionViewLayout) -> UICollectionViewTransitionLayout!

}
