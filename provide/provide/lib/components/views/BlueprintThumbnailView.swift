//
//  BlueprintThumbnailView.swift
//  provide
//
//  Created by Kyle Thomas on 10/24/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol BlueprintThumbnailViewDelegate: NSObjectProtocol {
    func blueprintThumbnailViewNavigationBegan(view: BlueprintThumbnailView)
    func blueprintThumbnailViewNavigationEnded(view: BlueprintThumbnailView)
    func blueprintThumbnailView(view: BlueprintThumbnailView, navigatedToFrame frame: CGRect)
    func initialScaleForBlueprintThumbnailView(view: BlueprintThumbnailView) -> CGFloat
    func sizeForBlueprintThumbnailView(view: BlueprintThumbnailView) -> CGSize
}

class BlueprintThumbnailView: UIView, BlueprintThumbnailOverlayViewDelegate {

    weak var delegate: BlueprintThumbnailViewDelegate!

    weak var blueprintImage: UIImage! {
        didSet {
            dispatch_after_delay(0.0) { [weak self, weak bluePrintImage = self.blueprintImage] in
                if let s = self {
                    s.frame = CGRect(x: s.visibleSize.width - s.desiredSize.width - 10.0,
                        y: s.visibleSize.height - s.desiredSize.height - 10.0 - 44.0,
                        width: s.desiredSize.width,
                        height: s.desiredSize.height)

                    if let bluePrintImage = bluePrintImage {
                        let scaledImage = bluePrintImage.scaledToWidth(s.desiredSize.width)
                        s.thumbnailImageBackgroundView.frame.size = s.desiredSize
                        s.thumbnailImageBackgroundView.backgroundColor = UIColor(patternImage: scaledImage)

                        var scale = CGFloat(1.0)
                        if let delegate = s.delegate {
                            scale = delegate.initialScaleForBlueprintThumbnailView(s)
                        }
                        s.resizeOverlayView(CGPointZero, scale: scale)
                    } else {
                        s.alpha = 0.0
                    }
                }
            }
        }
    }

    @IBOutlet private weak var thumbnailImageBackgroundView: UIView!

    @IBOutlet private weak var overlayView: BlueprintThumbnailOverlayView! {
        didSet {
            if let overlayView = overlayView {
                overlayView.delegate = self
                overlayView.alpha = 0.0
                overlayView.addBorder(3.0, color: UIColor.blackColor())
            }
        }
    }

    private var desiredSize: CGSize {
        var desiredSize = CGSize(width: 200.0, height: 215.0)
        if let delegate = delegate {
            desiredSize = delegate.sizeForBlueprintThumbnailView(self)
        }
        return desiredSize
    }

    private var visibleSize: CGSize {
        if let superview = self.superview {
            return superview.frame.size
        }
        return CGSizeZero
    }

    private var viewportAspectRatio: CGFloat {
        return visibleSize.width / visibleSize.height
    }

    private func resizeOverlayView(origin: CGPoint = CGPointZero, scale: CGFloat = 1.0) {
        if let blueprintImage = blueprintImage {
            let heightRatio = visibleSize.height / (blueprintImage.size.height * scale)

            let viewportHeight = frame.height * heightRatio
            let viewportWidth = viewportHeight * viewportAspectRatio

            dispatch_after_delay(0.0) { [weak self] in
                self?.overlayView.frame = CGRect(x: origin.x,
                                                 y: origin.y,
                                                 width: viewportWidth,
                                                 height: viewportHeight)

                self?.overlayView.alpha = 1.0
            }
        }
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentSize.height > 0 && scrollView.contentSize.width > 0 {
            let xScale = (scrollView.contentOffset.x + scrollView.contentInset.left) / scrollView.contentSize.width
            let yScale = (scrollView.contentOffset.y + scrollView.contentInset.top) / scrollView.contentSize.height

            if let overlayView = overlayView {
                overlayView.frame = CGRect(x: max(0.0, min(frame.width - overlayView.frame.width, frame.width * xScale)),
                                           y: max(0.0, min(frame.height - overlayView.frame.height, frame.height * yScale)),
                                           width: overlayView.frame.width,
                                           height: overlayView.frame.height)
            }
        }
    }

    func scrollViewDidZoom(scrollView: UIScrollView) {
        if let _ = blueprintImage {
            let xScale = (scrollView.contentOffset.x + scrollView.contentInset.left) / scrollView.contentSize.width
            let yScale = (scrollView.contentOffset.y + scrollView.contentInset.top) / scrollView.contentSize.height
            let origin = CGPoint(x: frame.width * xScale, y: frame.height * yScale)
            let scale = scrollView.contentSize.height / blueprintImage.size.height
            resizeOverlayView(origin, scale: scale)
        }
    }

    // MARK: BlueprintThumbnailOverlayViewDelegate

    func blueprintThumbnailOverlayView(view: BlueprintThumbnailOverlayView, navigatedToFrame frame: CGRect) {
        delegate?.blueprintThumbnailView(self, navigatedToFrame: frame)
    }

    func blueprintThumbnailOverlayViewNavigationBegan(view: BlueprintThumbnailOverlayView) {
        delegate?.blueprintThumbnailViewNavigationBegan(self)
    }

    func blueprintThumbnailOverlayViewNavigationEnded(view: BlueprintThumbnailOverlayView) {
        delegate?.blueprintThumbnailViewNavigationEnded(self)
    }
}
