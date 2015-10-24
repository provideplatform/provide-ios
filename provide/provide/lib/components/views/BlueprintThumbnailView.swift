//
//  BlueprintThumbnailView.swift
//  provide
//
//  Created by Kyle Thomas on 10/24/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol BlueprintThumbnailViewDelegate {
    func blueprintThumbnailView(view: BlueprintThumbnailView, navigatedToFrame frame: CGRect)
    func sizeForBlueprintThumbnailView(view: BlueprintThumbnailView) -> CGSize
}

class BlueprintThumbnailView: UIView, BlueprintThumbnailOverlayViewDelegate {

    var delegate: BlueprintThumbnailViewDelegate!

    var blueprintImage: UIImage! {
        didSet {
            let visibleSize = self.superview!.frame.size

            var desiredSize = CGSize(width: 200.0, height: 215.0)
            if let delegate = delegate {
                desiredSize = delegate.sizeForBlueprintThumbnailView(self)
            }

            thumbnailImageView.frame = CGRect(x: 0.0,
                                              y: 0.0,
                                              width: desiredSize.width,
                                              height: desiredSize.height)

            thumbnailImageView.contentMode = .ScaleToFill
            thumbnailImageView.image = blueprintImage

            dispatch_after_delay(0.0) {
                self.frame = CGRect(x: visibleSize.width - desiredSize.width - 10.0,
                                    y: visibleSize.height - desiredSize.height - 10.0,
                                    width: desiredSize.width,
                                    height: desiredSize.height)

                if let _ = self.blueprintImage {
                    let viewportAspectRatio = CGFloat(visibleSize.width / visibleSize.height)
                    let heightRatio = visibleSize.height / self.blueprintImage.size.height

                    let viewportHeight = self.frame.height * heightRatio
                    let viewportWidth = viewportHeight * viewportAspectRatio

                    dispatch_after_delay(0.0) {
                        self.overlayView.frame = CGRect(x: 0.0,
                                                        y: 0.0,
                                                        width: viewportWidth,
                                                        height: viewportHeight)
                    }

                    self.alpha = 1.0
                } else {
                    self.alpha = 0.0
                }
            }
        }
    }

    @IBOutlet private weak var thumbnailImageView: UIImageView!

    @IBOutlet private weak var overlayView: BlueprintThumbnailOverlayView! {
        didSet {
            if let overlayView = overlayView {
                overlayView.delegate = self
                overlayView.addBorder(3.0, color: UIColor.blackColor())
            }
        }
    }

    // MARK: BlueprintThumbnailOverlayViewDelegate

    func blueprintThumbnailOverlayView(view: BlueprintThumbnailOverlayView, navigatedToFrame frame: CGRect) {
        delegate?.blueprintThumbnailView(self, navigatedToFrame: frame)
    }
}