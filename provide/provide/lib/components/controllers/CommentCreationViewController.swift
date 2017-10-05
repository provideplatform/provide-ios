//
//  CommentCreationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol CommentCreationViewControllerDelegate {
    func commentCreationViewController(_ viewController: CommentCreationViewController, didSubmitComment comment: String)
    func commentCreationViewControllerShouldBeDismissed(_ viewController: CommentCreationViewController)
    func promptForCommentCreationViewController(_ viewController: CommentCreationViewController) -> String!
    func titleForCommentCreationViewController(_ viewController: CommentCreationViewController) -> String!
    @objc optional func saveItemForCommentCreationViewController(_ viewController: CommentCreationViewController) -> UIBarButtonItem!
    @objc optional func dismissItemForCommentCreationViewController(_ viewController: CommentCreationViewController) -> UIBarButtonItem!
}

class CommentCreationViewController: WorkOrderComponentViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITextViewDelegate {

    var commentCreationViewControllerDelegate: CommentCreationViewControllerDelegate!

    @IBOutlet fileprivate weak var collectionView: UICollectionView!
    @IBOutlet fileprivate weak var textView: UITextView!

    fileprivate var comments = [Comment]() {
        didSet {
            collectionView.reloadData()
        }
    }

    fileprivate var dismissItem: UIBarButtonItem! {
        if textView.text.length > 0 {
            if let dismissItem = commentCreationViewControllerDelegate?.saveItemForCommentCreationViewController?(self) {
                return dismissItem
            }
        } else if let dismissItem = commentCreationViewControllerDelegate?.dismissItemForCommentCreationViewController?(self) {
            return dismissItem
        }

        let title = textView.text.length > 0 ? "DISMISS + SAVE" : "DISMISS"
        let dismissItem = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(CommentCreationViewController.dismiss as (CommentCreationViewController) -> () -> Void))
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: .normal)
        return dismissItem
    }

    fileprivate var hiddenNavigationControllerFrame: CGRect {
        return CGRect(
            x: 0.0,
            y: targetView.frame.height,
            width: targetView.frame.width,
            height: targetView.frame.height / 1.333
        )
    }

    fileprivate var renderedNavigationControllerFrame: CGRect {
        return CGRect(
            x: 0.0,
            y: hiddenNavigationControllerFrame.origin.y - hiddenNavigationControllerFrame.height,
            width: hiddenNavigationControllerFrame.width,
            height: hiddenNavigationControllerFrame.height
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.text = ""

        setupNavigationItem()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        textView.becomeFirstResponder()
    }

    func dismiss() {
        if textView.text.length > 0 {
            commentCreationViewControllerDelegate?.commentCreationViewController(self, didSubmitComment: textView.text)
        } else {
            commentCreationViewControllerDelegate?.commentCreationViewControllerShouldBeDismissed(self)
        }
    }

    func setupNavigationItem() {
        navigationItem.prompt = commentCreationViewControllerDelegate?.promptForCommentCreationViewController(self)
        navigationItem.title = commentCreationViewControllerDelegate?.titleForCommentCreationViewController(self)
        navigationItem.hidesBackButton = true

        navigationItem.leftBarButtonItems = []
        navigationItem.rightBarButtonItems = [dismissItem]
    }

    override func render() {
        let frame = hiddenNavigationControllerFrame

        view.alpha = 0.0
        view.frame = frame

        if let navigationController = navigationController {
            navigationController.view.alpha = 0.0
            navigationController.view.frame = hiddenNavigationControllerFrame
            targetView.addSubview(navigationController.view)
            targetView.bringSubview(toFront: navigationController.view)

            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut,
                animations: {
                    self.view.alpha = 1
                    navigationController.view.alpha = 1
                    navigationController.view.frame = CGRect(
                        x: frame.origin.x,
                        y: frame.origin.y - navigationController.view.frame.height,
                        width: frame.width,
                        height: frame.height
                    )
                },
                completion: nil
            )
        }
    }

    override func unwind() {
        clearNavigationItem()

        if textView.isFirstResponder {
            textView.resignFirstResponder()
        }

        if let navigationController = navigationController {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut,
                animations: {
                    self.view.alpha = 0.0
                    navigationController.view.alpha = 0.0
                    navigationController.view.frame = self.hiddenNavigationControllerFrame
                },
                completion: nil
            )
        }
    }

    //    optional func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool
    //    optional func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath)
    //    optional func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath)
    //    optional func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool
    //    optional func collectionView(collectionView: UICollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool // called when the user taps on an already-selected item in multi-select mode
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

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return comments.count
    }

    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "commentCollectionViewCellReuseIdentifier", for: indexPath)

        return cell
    }

    //    optional func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int

    // The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
    //    optional func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView

    // MARK: UITextFieldDelegate

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return true
    }

    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        return true
    }

    //    optional func textViewDidBeginEditing(textView: UITextView)
    //    optional func textViewDidEndEditing(textView: UITextView)

    //    optional func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool

    func textViewDidChange(_ textView: UITextView) {
        setupNavigationItem()
    }

    //    optional func textViewDidChangeSelection(textView: UITextView)
    //
    //    @availability(iOS, introduced=7.0)
    //    optional func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool
    //    @availability(iOS, introduced=7.0)
    //    optional func textView(textView: UITextView, shouldInteractWithTextAttachment textAttachment: NSTextAttachment, inRange characterRange: NSRange) -> Bool
}
