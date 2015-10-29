//
//  BlueprintViewController.swift
//  provide
//
//  Created by Kyle Thomas on 10/23/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol BlueprintViewControllerDelegate {
//    func commentsViewController(viewController: CommentsViewController, didSubmitComment comment: String)
//    func commentsViewControllerShouldBeDismissed(viewController: CommentsViewController)
//    func promptForCommentsViewController(viewController: CommentsViewController) -> String!
//    func titleForCommentsViewController(viewController: CommentsViewController) -> String!
}

class BlueprintViewController: WorkOrderComponentViewController, UIScrollViewDelegate, BlueprintThumbnailViewDelegate, BlueprintToolbarDelegate {

    var blueprintViewControllerDelegate: BlueprintViewControllerDelegate!

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    @IBOutlet private weak var scrollView: UIScrollView!

    @IBOutlet private weak var toolbar: BlueprintToolbar!

    @IBOutlet private weak var thumbnailView: BlueprintThumbnailView! {
        didSet {
            if let thumbnailView = thumbnailView {
                thumbnailView.delegate = self
                thumbnailView.backgroundColor = UIColor.whiteColor() //.colorWithAlphaComponent(0.85)
                thumbnailView.roundCorners(5.0)
            }
        }
    }

    private var imageView: UIImageView!

    private var enableScrolling = false {
        didSet {
            if let scrollView = scrollView {
                scrollView.scrollEnabled = enableScrolling
            }
        }
    }

    private var workOrder: WorkOrder! {
        return WorkOrderService.sharedService().inProgressWorkOrder
    }

    private var hiddenNavigationControllerFrame: CGRect {
        return CGRect(
            x: 0.0,
            y: targetView.frame.height,
            width: targetView.frame.width,
            height: targetView.frame.height // / 1.333
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

        setupNavigationItem()

        imageView = UIImageView()
        imageView.alpha = 0.0

        scrollView.backgroundColor = UIColor(red: 0.11, green: 0.29, blue: 0.565, alpha: 0.45)

        toolbar.alpha = 0.0
        toolbar.blueprintToolbarDelegate = self

        hideToolbar()
        loadBlueprint()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

    }

    func dismiss() {

    }

    func setupNavigationItem() {
        navigationItem.hidesBackButton = true

        navigationItem.leftBarButtonItems = []
        navigationItem.rightBarButtonItems = []
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

    private func loadBlueprint() {
        if let workOrder = workOrder {
            if let url = workOrder.blueprintImageUrl {
                imageView.sd_setImageWithURL(url) { (image, error, cacheType, url) -> Void in
                    let size = CGSize(width: image.size.width, height: image.size.height)

                    self.thumbnailView.blueprintImage = image

                    self.imageView.frame = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
                    self.imageView.contentMode = .ScaleToFill

                    self.scrollView.contentSize = size
                    self.scrollView.scrollEnabled = false
                    self.scrollView.addSubview(self.imageView)
                    
                    self.enableScrolling = true

                    self.scrollView.minimumZoomScale = 0.25
                    self.scrollView.maximumZoomScale = 1.0
                    self.scrollView.zoomScale = 0.4

                    UIView.animateWithDuration(0.1, animations: { () -> Void in
                        self.scrollView.bringSubviewToFront(self.imageView)
                        self.imageView.alpha = 1.0

                        self.activityIndicatorView.stopAnimating()
                    })

                    self.showToolbar()
                }
            }
        }
    }

    private func hideToolbar() {
        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: {
                self.toolbar.alpha = 0.0
                self.toolbar.frame.origin.y += self.toolbar.frame.size.height
            }, completion: { completed in

            }
        )
    }

    private func showToolbar() {
        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: {
                self.toolbar.alpha = 1.0
                self.toolbar.frame.origin.y -= self.toolbar.frame.size.height
            }, completion: { completed in

            }
        )
    }

    // MARK: BlueprintThumbnailViewDelegate

    func blueprintThumbnailView(view: BlueprintThumbnailView, navigatedToFrame frame: CGRect) {
        let reenableScrolling = enableScrolling
        enableScrolling = false

        let xScale = frame.origin.x / view.frame.width
        let yScale = frame.origin.y / view.frame.height

        let contentSize = scrollView.contentSize
        let visibleFrame = CGRect(x: contentSize.width * xScale,
                                  y: contentSize.height * yScale,
                                  width: scrollView.frame.width,
                                  height: scrollView.frame.height)

        scrollView.setContentOffset(visibleFrame.origin, animated: false)

        if reenableScrolling {
            enableScrolling = true
        }
    }

    func blueprintThumbnailViewNavigationBegan(view: BlueprintThumbnailView) {
        hideToolbar()
    }

    func blueprintThumbnailViewNavigationEnded(view: BlueprintThumbnailView) {
        showToolbar()
    }

    func initialScaleForBlueprintThumbnailView(view: BlueprintThumbnailView) -> CGFloat {
        return 0.4
    }

    func sizeForBlueprintThumbnailView(view: BlueprintThumbnailView) -> CGSize {
        let imageSize = imageView.image!.size
        let aspectRatio = CGFloat(imageSize.width / imageSize.height)
        let height = CGFloat(imageSize.width > imageSize.height ? 225.0 : 375.0)
        let width = aspectRatio * height
        return CGSize(width: width, height: height)
    }

    // MARK: BlueprintToolbarDelegate

    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetNavigatorVisibility visible: Bool) {
        let alpha = CGFloat(visible ? 1.0 : 0.0)
        thumbnailView.alpha = alpha
    }

    // MARK: UIScrollViewDelegate

    func scrollViewDidScroll(scrollView: UIScrollView) {
        if enableScrolling {
            thumbnailView.scrollViewDidScroll(scrollView)
        }
    }

    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView?) {
        hideToolbar()
    }

    func scrollViewDidZoom(scrollView: UIScrollView) {
        thumbnailView.scrollViewDidZoom(scrollView)
    }

    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        let size = imageView.image!.size
        let width = size.width * scale
        let height = size.height * scale
        imageView.frame.size = CGSize(width: width, height: height)
        scrollView.contentSize = CGSize(width: width, height: height)

        showToolbar()
    }

//
//    @available(iOS 2.0, *)
//    optional public func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool // return a yes if you want to scroll to the top. if not defined, assumes YES
//    @available(iOS 2.0, *)
//    optional public func scrollViewDidScrollToTop(scrollView: UIScrollView) // called when scrolling animation finished. may be called immediately if already at top
}
