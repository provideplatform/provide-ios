//
//  CommentsViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/20/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol CommentsViewControllerDelegate {
    func commentsViewController(viewController: CommentsViewController, shouldCreateComment comment: String)
    func commentsForCommentsViewController(viewController: CommentsViewController) -> [Comment]
}

class CommentsViewController: ViewController, UICollectionViewDelegate, UICollectionViewDataSource, CommentCreationViewControllerDelegate {

    var commentsViewControllerDelegate: CommentsViewControllerDelegate!

    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var zeroStateLabel: UILabel!

    @IBOutlet private weak var addCommentBarButtonItem: UIBarButtonItem! {
        didSet {
            if let addCommentBarButtonItem = addCommentBarButtonItem {
                let commentIconImage = FAKFontAwesome.commentIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0)).imageWithRenderingMode(.AlwaysTemplate)
                addCommentBarButtonItem.image = commentIconImage
                addCommentBarButtonItem.tintColor = UIColor.blackColor()
            }
        }
    }

    private var comments: [Comment] {
        if let comments = commentsViewControllerDelegate?.commentsForCommentsViewController(self) {
            return comments
        }
        return [Comment]()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "COMMENTS"

        navigationItem.title = "COMMENTS"

        if let navigationController = navigationController {
            navigationController.setNavigationBarHidden(true, animated: false)
        }

        zeroStateLabel?.alpha = 0.0
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier! == "CommentCreationViewControllerPopoverSegue" {
            let commentCreationViewController = (segue.destinationViewController as! UINavigationController).viewControllers.first! as! CommentCreationViewController
            commentCreationViewController.commentCreationViewControllerDelegate = self
            commentCreationViewController.preferredContentSize = CGSize(width: 400, height: 200)
            if let popoverPresentationController = commentCreationViewController.popoverPresentationController {
                popoverPresentationController.permittedArrowDirections = [.Down]
            }
        }
    }

    func reloadCollectionView() {
        collectionView?.reloadData()

        if comments.count == 0 {
            zeroStateLabel?.alpha = 1.0
        } else {
            zeroStateLabel?.alpha = 0.0
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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("commentCollectionViewCellReuseIdentifier", forIndexPath: indexPath) as! CommentCollectionViewCell
        cell.comment = comments[indexPath.row]
        return cell
    }

//    optional func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int

    // The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
//    optional func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView

    // MARK: CommentCreationViewControllerDelegate

    func commentCreationViewController(viewController: CommentCreationViewController, didSubmitComment comment: String) {
        commentsViewControllerDelegate?.commentsViewController(self, shouldCreateComment: comment)
        commentCreationViewControllerShouldBeDismissed(viewController)
    }

    func commentCreationViewControllerShouldBeDismissed(viewController: CommentCreationViewController) {
        if let presentingViewController = viewController.presentingViewController {
            presentingViewController.dismissViewController(animated: true)
        }
    }

    func promptForCommentCreationViewController(viewController: CommentCreationViewController) -> String! {
        return nil
    }

    func titleForCommentCreationViewController(viewController: CommentCreationViewController) -> String! {
        return "ADD COMMENT"
    }

    func dismissItemForCommentCreationViewController(viewController: CommentCreationViewController) -> UIBarButtonItem! {
        let dismissIconImage = FAKFontAwesome.closeIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0)).imageWithRenderingMode(.AlwaysTemplate)
        let dismissItem = UIBarButtonItem(image: dismissIconImage, style: .Plain, target: viewController, action: "dismiss")
        dismissItem.tintColor = UIColor.whiteColor()
        return dismissItem
    }

    func saveItemForCommentCreationViewController(viewController: CommentCreationViewController) -> UIBarButtonItem! {
        let saveIconImage = FAKFontAwesome.saveIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0)).imageWithRenderingMode(.AlwaysTemplate)
        let saveItem = UIBarButtonItem(image: saveIconImage, style: .Plain, target: viewController, action: "dismiss")
        saveItem.tintColor = UIColor.whiteColor()
        return saveItem
    }
}
