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

class BlueprintViewController: WorkOrderComponentViewController, UIScrollViewDelegate {

    var blueprintViewControllerDelegate: BlueprintViewControllerDelegate!

    @IBOutlet private weak var scrollView: UIScrollView!

    private var imageView: UIImageView!

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

        scrollView.backgroundColor = UIColor(red: 0.11, green: 0.29, blue: 0.565, alpha: 0.45)
        scrollView.addSubview(imageView)

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

                    self.imageView.frame = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
                    self.imageView.contentMode = .ScaleAspectFill

                    self.scrollView.contentSize = size

                    //            self.scrollView.minimumZoomScale = 0.25
                    //            self.scrollView.maximumZoomScale = 1.0
                    //            self.scrollView.zoomScale = 0.35
                    
                    self.scrollView.bringSubviewToFront(self.imageView)
                    // TODO: bring touch receiver overlay view to front
                }
            }
        }
    }

    // MARK: UIScrollViewDelegate

//    @available(iOS 2.0, *)
//    optional public func scrollViewDidScroll(scrollView: UIScrollView) // any offset changes
//    @available(iOS 3.2, *)
//    optional public func scrollViewDidZoom(scrollView: UIScrollView) // any zoom scale changes
//
//    // called on start of dragging (may require some time and or distance to move)
//    @available(iOS 2.0, *)
//    optional public func scrollViewWillBeginDragging(scrollView: UIScrollView)
//    // called on finger up if the user dragged. velocity is in points/millisecond. targetContentOffset may be changed to adjust where the scroll view comes to rest
//    @available(iOS 5.0, *)
//    optional public func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)
//    // called on finger up if the user dragged. decelerate is true if it will continue moving afterwards
//    @available(iOS 2.0, *)
//    optional public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool)
//
//    @available(iOS 2.0, *)
//    optional public func scrollViewWillBeginDecelerating(scrollView: UIScrollView) // called on finger up as we are moving
//    @available(iOS 2.0, *)
//    optional public func scrollViewDidEndDecelerating(scrollView: UIScrollView) // called when scroll view grinds to a halt
//
//    @available(iOS 2.0, *)
//    optional public func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) // called when setContentOffset/scrollRectVisible:animated: finishes. not called if not animating
//

//    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
//
//        return nil
//    }
//    @available(iOS 3.2, *)
//    optional public func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView?) // called before the scroll view begins zooming its content
//    @available(iOS 2.0, *)

//    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
//        let size = self.imageView.image!.size
//        //self.imageView.frame.size = CGSize(width: size.width * scale, height: size.height * scale)
//        //self.scrollView.contentSize = CGSize(width: size.width * scale, height: size.height * scale)
//    }

//
//    @available(iOS 2.0, *)
//    optional public func scrollViewShouldScrollToTop(scrollView: UIScrollView) -> Bool // return a yes if you want to scroll to the top. if not defined, assumes YES
//    @available(iOS 2.0, *)
//    optional public func scrollViewDidScrollToTop(scrollView: UIScrollView) // called when scrolling animation finished. may be called immediately if already at top
}
