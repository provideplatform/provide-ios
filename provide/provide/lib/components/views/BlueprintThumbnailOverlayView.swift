//
//  BlueprintThumbnailOverlayView.swift
//  provide
//
//  Created by Kyle Thomas on 10/24/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol BlueprintThumbnailOverlayViewDelegate {
    func blueprintThumbnailOverlayView(view: BlueprintThumbnailOverlayView, navigatedToFrame frame: CGRect)
}

class BlueprintThumbnailOverlayView: UIView {

    var delegate: BlueprintThumbnailOverlayViewDelegate!

    private var touchesBeganTimestamp: NSDate!

    private var gestureInProgress: Bool {
        return touchesBeganTimestamp != nil
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)

        touchesBeganTimestamp = NSDate()
        applyTouches(touches)
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)

        applyTouches(touches)
        touchesBeganTimestamp = nil
    }

    override func touchesCancelled(touches: Set<UITouch>!, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)

        touchesBeganTimestamp = nil
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        applyTouches(touches)
    }

    private func applyTouches(touches: Set<NSObject>) {
        for touch in touches {
            dragOverlay(touch as! UITouch)
        }
    }

    private func dragOverlay(touch: UITouch) {
        let xOffset = touch.locationInView(nil).x - touch.previousLocationInView(nil).x
        let x = frame.origin.x + xOffset

        let yOffset = touch.locationInView(nil).y - touch.previousLocationInView(nil).y
        let y = frame.origin.y + yOffset

        dragOverlay(x, y: y)
    }

    private func dragOverlay(var x: CGFloat, var y: CGFloat) {
        if x < 0.0 {
            x = 0.0
        } else if x > superview!.frame.width - frame.width {
            x = superview!.frame.width - frame.width
        }

        if y < 0.0 {
            y = 0.0
        } else if y > superview!.frame.height - frame.height {
            y = superview!.frame.height - frame.height
        }

        frame.origin.x = x
        frame.origin.y = y

        delegate?.blueprintThumbnailOverlayView(self, navigatedToFrame: frame)
    }
}
