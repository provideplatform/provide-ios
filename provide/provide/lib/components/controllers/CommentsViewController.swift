//
//  CommentsViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/20/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import FontAwesomeKit
import KTSwiftExtensions

protocol CommentsViewControllerDelegate {
    func commentsViewController(_ viewController: CommentsViewController, shouldCreateComment comment: String, withImageAttachment image: UIImage!)
    func commentableTypeForCommentsViewController(_ viewController: CommentsViewController) -> String
    func commentableIdForCommentsViewController(_ viewController: CommentsViewController) -> Int
    func queryParamsForCommentsViewController(_ viewController: CommentsViewController) -> [String : AnyObject]!
}

class CommentsViewController: WorkOrderComponentViewController, UICollectionViewDelegate, UICollectionViewDataSource, CommentCreationViewControllerDelegate {

    var commentsViewControllerDelegate: CommentsViewControllerDelegate! {
        didSet {
            if let _ = commentsViewControllerDelegate {
                reset()
            }
        }
    }

    @IBOutlet fileprivate weak var collectionView: UICollectionView!
    @IBOutlet fileprivate weak var zeroStateLabel: UILabel!
    @IBOutlet fileprivate weak var activityIndicatorView: UIActivityIndicatorView!

    fileprivate var refreshControl: UIRefreshControl!

    @IBOutlet fileprivate weak var addCommentBarButtonItem: UIBarButtonItem! {
        didSet {
            if let addCommentBarButtonItem = addCommentBarButtonItem {
                let commentIconImage = FAKFontAwesome.commentIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0)).withRenderingMode(.alwaysTemplate)
                addCommentBarButtonItem.image = commentIconImage
                addCommentBarButtonItem.tintColor = Color.applicationDefaultBarButtonItemTintColor()
            }
        }
    }

    fileprivate var comments = [Comment]()

    fileprivate var page = 1
    fileprivate var rpp = 10
    fileprivate var hasNextPage = true

    fileprivate var fetchingComments = false
    fileprivate var scrolledToNewestComment = false

    func scrollToNewestComment(_ animated: Bool = true) {
        if comments.count > 0 {
            collectionView?.scrollToItem(at: IndexPath(item: comments.count - 1, section: 0), at: .bottom, animated: animated)
        }

        scrolledToNewestComment = true
    }

    override func showActivity() {
        activityIndicatorView?.startAnimating()
    }

    override func hideActivity() {
        activityIndicatorView?.stopAnimating()
        refreshControl?.endRefreshing()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "COMMENTS"

        navigationItem.title = "COMMENTS"

//        if let navigationController = navigationController {
//            navigationController.setNavigationBarHidden(true, animated: false)
//        }

        setupPullToRefresh()

        activityIndicatorView.startAnimating()
        view.bringSubview(toFront: activityIndicatorView)

        zeroStateLabel?.alpha = 0.0

        NotificationCenter.default.addObserverForName("CommentChanged") { notification in
            if let comment = notification.object as? Comment {
                DispatchQueue.main.async {
                    let commentableType = self.commentsViewControllerDelegate?.commentableTypeForCommentsViewController(self)
                    let commentableId = self.commentsViewControllerDelegate?.commentableIdForCommentsViewController(self)
                    var indexPath = 0
                    var updatedExistingComment = false
                    if commentableType != nil && commentableId != nil && comment.commentableType == commentableType && comment.commentableId == commentableId {
                        for c in self.comments.reversed() {
                            if c.id == comment.id {
                                self.collectionView.reloadItems(at: [IndexPath(row: indexPath, section: 0)])
                                updatedExistingComment = true
                            }

                            indexPath += 1
                        }

                        if !updatedExistingComment {
                            indexPath = -1
                            var i = -1
                            for c in self.comments.reversed() {
                                i += 1
                                if c.id == comment.previousCommentId {
                                    indexPath = i
                                    break
                                }
                            }

                            if indexPath != -1 {
                                if indexPath == self.comments.count - 1 {
                                    self.addComment(comment)
                                } else {
                                    indexPath = self.comments.count - indexPath // inverse
                                    self.comments.insert(comment, at: indexPath)
                                    self.performBatchUpdatesAtIndexPaths([IndexPath(row: indexPath, section: 0)])
                                }
                            }
                        }
                    }
                }
            }
        }

        NotificationCenter.default.addObserverForName("WorkOrderChanged") { notification in
            if let workOrder = notification.object as? WorkOrder {
                DispatchQueue.main.async {
                    var indexPath = 0
                    for comment in self.comments {
                        if comment.isWorkOrderComment {
                            if comment.commentableId == workOrder.id {
                                self.collectionView.reloadItems(at: [IndexPath(row: indexPath, section: 0)])
                            }
                        }

                        indexPath += 1
                    }
                }
            }
        }
    }

    fileprivate func setupPullToRefresh() {
        refreshControl = UIRefreshControl()
        //refreshControl.addTarget(self, action: #selector(refresh), forControlEvents: .ValueChanged)

        collectionView.addSubview(refreshControl)
        //collectionView.alwaysBounceVertical = true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier! == "CommentCreationViewControllerPopoverSegue" {
            let commentCreationViewController = (segue.destination as! UINavigationController).viewControllers.first! as! CommentCreationViewController
            commentCreationViewController.commentCreationViewControllerDelegate = self
            commentCreationViewController.preferredContentSize = CGSize(width: 400, height: 200)
            if let popoverPresentationController = commentCreationViewController.popoverPresentationController {
                popoverPresentationController.permittedArrowDirections = [.down]
            }
        }
    }

    fileprivate func containsComment(_ comment: Comment) -> Bool {
        for c in comments {
            if c.id == comment.id && c.id > 0 {
                return true
            }
        }
        return false
    }

    func addComment(_ comment: Comment) {
        if !containsComment(comment) {
            comments.insert(comment, at: 0)
            performBatchUpdatesAtIndexPaths([IndexPath(row: self.comments.count - 1, section: 0)])
        } else {
            for c in comments {
                if c.id == comment.id && c.id > 0 {
                    c.attachments = comment.attachments
                }
            }
            collectionView.reloadItems(at: [IndexPath(row: self.comments.count - 1, section: 0)])
        }

        zeroStateLabel?.alpha = 0.0
    }

    fileprivate func performBatchUpdatesAtIndexPaths(_ indexPaths: [IndexPath]) {
        let bottom = self.collectionView.contentSize.height - self.collectionView.contentOffset.y

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        self.collectionView.performBatchUpdates(
            {
                UIView.animate(withDuration: 0.0, animations: {
                    self.collectionView.insertItems(at: indexPaths)
                })
            },
            completion: { (completed) in
                self.collectionView.contentOffset = CGPoint(x: 0.0, y: self.collectionView.contentSize.height - bottom)
                CATransaction.commit()

                self.scrollToNewestComment()
                self.hideActivity()
            }
        )
    }

    func reset() {
        comments = [Comment]()
        page = 1
        hasNextPage = true
        scrolledToNewestComment = false
        refresh()
    }

    func refresh() {
        if fetchingComments || !hasNextPage {
            return
        }

        fetchingComments = true

        if var params = commentsViewControllerDelegate.queryParamsForCommentsViewController(self) {
            params["page"] = page as AnyObject
            params["rpp"] = rpp as AnyObject

            let commentableType = commentsViewControllerDelegate.commentableTypeForCommentsViewController(self)
            let commentableId = Int(commentsViewControllerDelegate.commentableIdForCommentsViewController(self))

            if commentableId > 0 {
                if page == 1 {
                    showActivity()
                } else {
                    refreshControl?.beginRefreshing()
                }

                ApiService.sharedService().fetchComments(params, forCommentableType: commentableType, withCommentableId: String(commentableId),
                                                         onSuccess: { statusCode, mappingResult in
                                                            let fetchedComments = mappingResult?.array() as! [Comment]
                                                            if self.page == 1 {
                                                                self.comments = [Comment]()
                                                            }
                                                            self.comments += fetchedComments

                                                            self.hasNextPage = fetchedComments.count == self.rpp

                                                            if self.page == 1 {
                                                                self.reloadCollectionView()
                                                            } else {
                                                                var indexPaths = [IndexPath]()
                                                                var indexPath = 0
                                                                for _ in fetchedComments {
                                                                    indexPaths.append(IndexPath(row: indexPath, section: 0))
                                                                    indexPath += 1
                                                                }

                                                                let bottom = self.collectionView.contentSize.height - self.collectionView.contentOffset.y

                                                                CATransaction.begin()
                                                                CATransaction.setDisableActions(true)

                                                                self.collectionView.performBatchUpdates(
                                                                    {
                                                                        UIView.animate(withDuration: 0.0, animations: {
                                                                            self.collectionView.insertItems(at: indexPaths)
                                                                        })
                                                                    },
                                                                    completion: { (completed) in
                                                                        self.collectionView.contentOffset = CGPoint(x: 0, y: self.collectionView.contentSize.height - bottom)
                                                                        CATransaction.commit()
                                                                        self.hideActivity()
                                                                    }
                                                                )
                                                            }

                                                            self.page += 1

                                                            self.fetchingComments = false

                                                            if !self.hasNextPage {
                                                                self.refreshControl?.removeFromSuperview()
                                                                self.refreshControl = nil
                                                            }
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

        DispatchQueue.main.async {
            self.scrollToNewestComment(self.scrolledToNewestComment)
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

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).row == 0 {
            if scrolledToNewestComment {
                self.refresh()
            }
        }
    }

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

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10.0, left: 10.0, bottom: 0.0, right: 10.0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        let inset = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 0.0, right: 10.0)
        let insetWidthOffset = inset.left + inset.right
        if let superview = collectionView.superview {
            return CGSize(width: superview.bounds.width - insetWidthOffset, height: 125.0)
        }
        return CGSize(width: collectionView.bounds.width - insetWidthOffset, height: 125.0)
    }

    //    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
    //    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return comments.count
    }

    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "commentCollectionViewCellReuseIdentifier", for: indexPath) as! CommentCollectionViewCell
        if (indexPath as NSIndexPath).row <= comments.count - 1 {
            cell.comment = comments.reversed()[(indexPath as NSIndexPath).row]
        } else {
            cell.comment = nil
        }
        return cell
    }

//    optional func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int

    // The view that is returned must be retrieved from a call to -dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:
//    optional func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView

    // MARK: CommentCreationViewControllerDelegate

    func commentCreationViewController(_ viewController: CommentCreationViewController, didSubmitComment comment: String) {
        commentsViewControllerDelegate?.commentsViewController(self, shouldCreateComment: comment, withImageAttachment: nil)
        commentCreationViewControllerShouldBeDismissed(viewController)
    }

    func commentCreationViewControllerShouldBeDismissed(_ viewController: CommentCreationViewController) {
        if let presentingViewController = viewController.presentingViewController {
            presentingViewController.dismissViewController(true)
        }
    }

    func promptForCommentCreationViewController(_ viewController: CommentCreationViewController) -> String! {
        return nil
    }

    func titleForCommentCreationViewController(_ viewController: CommentCreationViewController) -> String! {
        return "ADD COMMENT"
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
