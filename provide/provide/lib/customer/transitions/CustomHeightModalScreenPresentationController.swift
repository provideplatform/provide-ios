//
//  CustomHeightModalPresentationController.swift
//  provide
//
//  Created by Jawwad Ahmad on 10/30/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

final class CustomHeightModalPresentationController: UIPresentationController {
    private var touchForwardingView: CustomHeightModalTouchForwardingView!

    private var height: CGFloat

    init(height: CGFloat, presentedViewController: UIViewController, presenting: UIViewController?) {
        self.height = height
        super.init(presentedViewController: presentedViewController, presenting: presenting)
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        return CGRect(x: 0, y: containerView!.bounds.height - height, width: containerView!.bounds.width, height: height)
    }

    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()

        touchForwardingView = CustomHeightModalTouchForwardingView(frame: containerView!.bounds)
        touchForwardingView.passthroughView = presentingViewController.view
        containerView?.insertSubview(touchForwardingView, at: 0)
    }
}
