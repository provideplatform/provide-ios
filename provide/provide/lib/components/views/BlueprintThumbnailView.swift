//
//  BlueprintThumbnailView.swift
//  provide
//
//  Created by Kyle Thomas on 10/24/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class BlueprintThumbnailView: UIView {

    var blueprintImage: UIImage! {
        didSet {
            thumbnailImageView.contentMode = .ScaleAspectFit
            thumbnailImageView.image = blueprintImage

            dispatch_after_delay(0.0) {
                self.frame = CGRect(x: self.superview!.frame.width - 200.0 - 10.0,
                                    y: self.superview!.frame.height - 215.0 - 10.0,
                                    width: 200.0,
                                    height: 215.0)

                if let _ = self.blueprintImage {
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
                overlayView.addBorder(3.0, color: UIColor.blackColor())
            }
        }
    }
}
