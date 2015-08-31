//
//  CommentsViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/20/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol CommentsViewControllerDelegate {
    func commentsViewController(viewController: CommentsViewController, didSubmitComment comment: String)
    func commentsViewControllerShouldBeDismissed(viewController: CommentsViewController)
    func promptForCommentsViewController(viewController: CommentsViewController) -> String!
    func titleForCommentsViewController(viewController: CommentsViewController) -> String!
}

class CommentsViewController: WorkOrderComponentViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITextViewDelegate {

    var commentsViewControllerDelegate: CommentsViewControllerDelegate!

    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var textView: UITextView!

    private var comments = [Comment]() {
        didSet {
            collectionView.reloadData()
        }
    }

    private var dismissItem: UIBarButtonItem! {
        let title = textView.text.length > 0 ? "DISMISS + SAVE" : "DISMISS"
        let dismissItem = UIBarButtonItem(title: title, style: .Plain, target: self, action: "dismiss")
        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
        return dismissItem
    }

    private var hiddenNavigationControllerFrame: CGRect {
        return CGRect(
            x: 0.0,
            y: targetView.frame.height,
            width: targetView.frame.width,
            height: targetView.frame.height / 1.333
        )
    }

    private var renderedNavigationControllerFrame: CGRect {
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

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        textView.becomeFirstResponder()
    }

    func dismiss() {
        if textView.text.length > 0 {
            commentsViewControllerDelegate?.commentsViewController(self, didSubmitComment: textView.text)
        } else {
            commentsViewControllerDelegate?.commentsViewControllerShouldBeDismissed(self)
        }
    }

    func setupNavigationItem() {
        navigationItem.prompt = commentsViewControllerDelegate?.promptForCommentsViewController(self)
        navigationItem.title = commentsViewControllerDelegate?.titleForCommentsViewController(self)
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
            targetView.bringSubviewToFront(navigationController.view)

            UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
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

        if textView.isFirstResponder() {
            textView.resignFirstResponder()
        }

        if let navigationController = navigationController {
            UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
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

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return comments.count
    }

    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("commentCollectionViewCellReuseIdentifier", forIndexPath: indexPath)

        return cell
    }

//    optional func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int

    // The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
//    optional func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView

    // MARK: UITextFieldDelegate

    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        return true
    }
    
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        return true
    }

//    optional func textViewDidBeginEditing(textView: UITextView)
//    optional func textViewDidEndEditing(textView: UITextView)

//    optional func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool

    func textViewDidChange(textView: UITextView) {
        setupNavigationItem()
    }

//    optional func textViewDidChangeSelection(textView: UITextView)
//
//    @availability(iOS, introduced=7.0)
//    optional func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool
//    @availability(iOS, introduced=7.0)
//    optional func textView(textView: UITextView, shouldInteractWithTextAttachment textAttachment: NSTextAttachment, inRange characterRange: NSRange) -> Bool
}