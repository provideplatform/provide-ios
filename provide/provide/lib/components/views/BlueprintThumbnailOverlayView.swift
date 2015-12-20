//
//  BlueprintThumbnailOverlayView.swift
//  provide
//
//  Created by Kyle Thomas on 10/24/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol BlueprintThumbnailOverlayViewDelegate: NSObjectProtocol {
    func blueprintThumbnailOverlayViewNavigationBegan(view: BlueprintThumbnailOverlayView)
    func blueprintThumbnailOverlayViewNavigationEnded(view: BlueprintThumbnailOverlayView)
    func blueprintThumbnailOverlayView(view: BlueprintThumbnailOverlayView, navigatedToFrame frame: CGRect)
}

class BlueprintThumbnailOverlayView: UIView {

    weak var delegate: BlueprintThumbnailOverlayViewDelegate!

    private var touchesBeganTimestamp: NSDate!

    private var gestureInProgress: Bool {
        return touchesBeganTimestamp != nil
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)

        delegate?.blueprintThumbnailOverlayViewNavigationBegan(self)

        touchesBeganTimestamp = NSDate()
        applyTouches(touches)
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)

        delegate?.blueprintThumbnailOverlayViewNavigationEnded(self)

        applyTouches(touches)
        touchesBeganTimestamp = nil
    }

    override func touchesCancelled(touches: Set<UITouch>!, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)

        delegate?.blueprintThumbnailOverlayViewNavigationEnded(self)

        touchesBeganTimestamp = nil
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        applyTouches(touches)
    }

    private func applyTouches(touches: Set<UITouch>) {
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0

        for touch in touches {
            xOffset += touch.locationInView(nil).x - touch.previousLocationInView(nil).x
            yOffset += touch.locationInView(nil).y - touch.previousLocationInView(nil).y

            dragOverlay(xOffset, yOffset: yOffset)
        }
    }

    private func dragOverlay(xOffset: CGFloat, yOffset: CGFloat) {
        var newFrame = CGRect(origin: frame.origin, size: frame.size)
        newFrame.origin.x += xOffset
        newFrame.origin.y += yOffset

        let x = newFrame.origin.x
        let y = newFrame.origin.y

        if x < 0.0 {
            newFrame.origin.x = 0.0
        } else if x > superview!.frame.width - frame.width {
            newFrame.origin.x = superview!.frame.width - frame.width
        }

        if y < 0.0 {
            newFrame.origin.y = 0.0
        } else if y > superview!.frame.height - frame.height {
            newFrame.origin.y = superview!.frame.height - frame.height
        }

        frame = newFrame

        delegate?.blueprintThumbnailOverlayView(self, navigatedToFrame: frame)
    }
}
