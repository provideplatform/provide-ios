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
    func commentableTypeForCommentsViewController(viewController: CommentsViewController) -> String
    func commentableIdForCommentsViewController(viewController: CommentsViewController) -> String
    func queryParamsForCommentsViewController(viewController: CommentsViewController) -> [String : AnyObject]!
}

class CommentsViewController: ViewController, UICollectionViewDelegate, UICollectionViewDataSource, CommentCreationViewControllerDelegate {

    var commentsViewControllerDelegate: CommentsViewControllerDelegate! {
        didSet {
            if let _ = commentsViewControllerDelegate {
                reset()
            }
        }
    }

    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var zeroStateLabel: UILabel!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    @IBOutlet private weak var addCommentBarButtonItem: UIBarButtonItem! {
        didSet {
            if let addCommentBarButtonItem = addCommentBarButtonItem {
                let commentIconImage = FAKFontAwesome.commentIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0)).imageWithRenderingMode(.AlwaysTemplate)
                addCommentBarButtonItem.image = commentIconImage
                addCommentBarButtonItem.tintColor = Color.applicationDefaultBarButtonItemTintColor()
            }
        }
    }

    private var comments = [Comment]()

    private var page = 1
    private var rpp = 10

    private var fetchingComments = false

    func scrollToNewestComment(animated: Bool = true) {
        collectionView?.scrollToItemAtIndexPath(NSIndexPath(forItem: comments.count - 1, inSection: 0), atScrollPosition: .Top, animated: animated)
    }

    override func showActivity() {
        activityIndicatorView?.startAnimating()
    }

    override func hideActivity() {
        activityIndicatorView?.stopAnimating()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "COMMENTS"

        navigationItem.title = "COMMENTS"

//        if let navigationController = navigationController {
//            navigationController.setNavigationBarHidden(true, animated: false)
//        }

        activityIndicatorView.startAnimating()
        view.bringSubviewToFront(activityIndicatorView)

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

    func addComment(comment: Comment) {
        comments.append(comment)
        reloadCollectionView()
        scrollToNewestComment()
    }

    func reset() {
        comments = [Comment]()
        page = 1
        refresh()
    }

    func refresh() {
        if fetchingComments {
            return
        }

        fetchingComments = true

        if var params = commentsViewControllerDelegate.queryParamsForCommentsViewController(self) {
            params["page"] = page
            params["rpp"] = rpp

            let commentableType = commentsViewControllerDelegate.commentableTypeForCommentsViewController(self)
            let commentableId = commentsViewControllerDelegate.commentableIdForCommentsViewController(self)

            if Int(commentableId) > 0 {
                if page == 1 {
                    showActivity()
                }

                ApiService.sharedService().fetchComments(params, forCommentableType: commentableType, withCommentableId: commentableId,
                                                         onSuccess: { statusCode, mappingResult in
                                                            let fetchedComments = mappingResult.array() as! [Comment]
                                                            if self.page == 1 {
                                                                self.comments = [Comment]()
                                                            }
                                                            self.comments += fetchedComments

                                                            self.page += 1
                                                            self.reloadCollectionView()

                                                            self.fetchingComments = false
                    },
                                                         onError: { error, statusCode, responseString in
                                                            self.fetchingComments = false
                    }
                )
            } else {
                reloadCollectionView()
                fetchingComments = false
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

        hideActivity()
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

    // MARK: UICollectionViewDelegate

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(10.0, 10.0, 0.0, 10.0)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let inset = UIEdgeInsetsMake(10.0, 10.0, 0.0, 10.0)
        let insetWidthOffset = inset.left + inset.right
        if let superview = collectionView.superview {
            return CGSizeMake(superview.bounds.width - insetWidthOffset, 125.0)
        }
        return CGSizeMake(collectionView.bounds.width - insetWidthOffset, 125.0)
    }

    //    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
    //    }

    func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
    }

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
        let dismissItem = UIBarButtonItem(image: dismissIconImage, style: .Plain, target: viewController, action: Selector("dismiss"))
        dismissItem.tintColor = Color.applicationDefaultBarButtonItemTintColor()
        return dismissItem
    }

    func saveItemForCommentCreationViewController(viewController: CommentCreationViewController) -> UIBarButtonItem! {
        let saveIconImage = FAKFontAwesome.saveIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0)).imageWithRenderingMode(.AlwaysTemplate)
        let saveItem = UIBarButtonItem(image: saveIconImage, style: .Plain, target: viewController, action: Selector("dismiss"))
        saveItem.tintColor = Color.applicationDefaultBarButtonItemTintColor()
        return saveItem
    }
}
