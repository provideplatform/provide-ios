//
//  FloorplanThumbnailView.swift
//  provide
//
//  Created by Kyle Thomas on 10/24/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

protocol FloorplanThumbnailViewDelegate: NSObjectProtocol {
    func floorplanThumbnailViewNavigationBegan(_ view: FloorplanThumbnailView)
    func floorplanThumbnailViewNavigationEnded(_ view: FloorplanThumbnailView)
    func floorplanThumbnailView(_ view: FloorplanThumbnailView, navigatedToFrame frame: CGRect)
    func initialScaleForFloorplanThumbnailView(_ view: FloorplanThumbnailView) -> CGFloat
    func sizeForFloorplanThumbnailView(_ view: FloorplanThumbnailView) -> CGSize
    func sizeForFloorplanThumbnailImageForFloorplanThumbnailView(_ view: FloorplanThumbnailView) -> CGSize!
    func offsetSizeForFloorplanThumbnailView(_ view: FloorplanThumbnailView) -> CGSize
}

class FloorplanThumbnailView: UIView, FloorplanThumbnailOverlayViewDelegate {

    weak var delegate: FloorplanThumbnailViewDelegate!

    weak var floorplanImage: UIImage! {
        didSet {
            dispatch_after_delay(0.0) { [weak self, weak bluePrintImage = self.floorplanImage] in
                self!.frame = CGRect(x: self!.visibleSize.width - self!.desiredSize.width - 10.0,
                                     y: self!.visibleSize.height - self!.desiredSize.height - 10.0 - 44.0,
                                     width: self!.desiredSize.width,
                                     height: self!.desiredSize.height)

                if let bluePrintImage = bluePrintImage {
                    if let scaledImage = bluePrintImage.scaledToWidth(self!.desiredSize.width) {
                        self!.thumbnailImageBackgroundView.frame.size = self!.desiredSize
                        self!.thumbnailImageBackgroundView.backgroundColor = UIColor(patternImage: scaledImage)

                        if let delegate = self!.delegate {
                            let scale = delegate.initialScaleForFloorplanThumbnailView(self!)
                            self!.resizeOverlayView(CGPoint.zero, scale: scale)
                        }
                    }
                } else {
                    self!.alpha = 0.0
                }
            }
        }
    }

    @IBOutlet fileprivate weak var thumbnailImageBackgroundView: UIView!

    @IBOutlet fileprivate weak var overlayView: FloorplanThumbnailOverlayView! {
        didSet {
            if let overlayView = overlayView {
                overlayView.delegate = self
                overlayView.alpha = 0.0
                overlayView.addBorder(3.0, color: UIColor.black)
            }
        }
    }

    fileprivate var desiredSize: CGSize {
        var desiredSize = CGSize(width: 200.0, height: 215.0)
        if let delegate = delegate {
            desiredSize = delegate.sizeForFloorplanThumbnailView(self)
        }
        return desiredSize
    }

    fileprivate var visibleSize: CGSize {
        if let superview = self.superview {
            return superview.frame.size
        }
        return CGSize.zero
    }

    fileprivate var viewportAspectRatio: CGFloat {
        return visibleSize.width / visibleSize.height
    }

    fileprivate func resizeOverlayView(_ origin: CGPoint = CGPoint.zero, scale: CGFloat = 1.0) {
        if let floorplanImage = floorplanImage {
            let floorplanImageSize = delegate?.sizeForFloorplanThumbnailImageForFloorplanThumbnailView(self) ?? floorplanImage.size
            let heightRatio = visibleSize.height / (floorplanImageSize.height * scale)

            let viewportHeight = frame.height * heightRatio
            let viewportWidth = viewportHeight * viewportAspectRatio

            dispatch_after_delay(0.0) { [weak self] in
                self!.overlayView.frame = CGRect(x: origin.x,
                                                 y: origin.y,
                                                 width: viewportWidth,
                                                 height: viewportHeight)

                self!.overlayView.alpha = 1.0
            }
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentSize.height > 0 && scrollView.contentSize.width > 0 {
            let offsetSize = delegate?.offsetSizeForFloorplanThumbnailView(self) ?? CGSize.zero
            let xScale = (scrollView.contentOffset.x + scrollView.contentInset.left) / (scrollView.contentSize.width - offsetSize.width)
            let yScale = (scrollView.contentOffset.y + scrollView.contentInset.top) / (scrollView.contentSize.height - offsetSize.height)

            if let overlayView = overlayView {
                overlayView.frame = CGRect(x: max(0.0, min(frame.width - overlayView.frame.width, frame.width * xScale)),
                                           y: max(0.0, min(frame.height - overlayView.frame.height, frame.height * yScale)),
                                           width: overlayView.frame.width,
                                           height: overlayView.frame.height)
            }
        }
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if frame.size == CGSize.zero {
            return
        }

        if let _ = floorplanImage {
            let offsetSize = delegate?.offsetSizeForFloorplanThumbnailView(self) ?? CGSize.zero
            let xScale = (scrollView.contentOffset.x + scrollView.contentInset.left) / (scrollView.contentSize.width - offsetSize.width)
            let yScale = (scrollView.contentOffset.y + scrollView.contentInset.top) / (scrollView.contentSize.height - offsetSize.height)
            let origin = CGPoint(x: frame.width * xScale, y: frame.height * yScale)
            let floorplanImageSize = delegate?.sizeForFloorplanThumbnailImageForFloorplanThumbnailView(self) ?? floorplanImage.size
            let scale = scrollView.contentSize.height / floorplanImageSize.height
            resizeOverlayView(origin, scale: scale)
        }
    }

    // MARK: FloorplanThumbnailOverlayViewDelegate

    func floorplanThumbnailOverlayView(_ view: FloorplanThumbnailOverlayView, navigatedToFrame frame: CGRect) {
        delegate?.floorplanThumbnailView(self, navigatedToFrame: frame)
    }

    func floorplanThumbnailOverlayViewNavigationBegan(_ view: FloorplanThumbnailOverlayView) {
        delegate?.floorplanThumbnailViewNavigationBegan(self)
    }

    func floorplanThumbnailOverlayViewNavigationEnded(_ view: FloorplanThumbnailOverlayView) {
        delegate?.floorplanThumbnailViewNavigationEnded(self)
    }
}
