//
//  BlueprintThumbnailOverlayView.swift
//  provide
//
//  Created by Kyle Thomas on 10/24/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class BlueprintThumbnailOverlayView: UIView {

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
            dragMenu(touch as! UITouch)
        }
    }

    private func dragMenu(touch: UITouch) {
        let xOffset = touch.locationInView(nil).x - touch.previousLocationInView(nil).x
        let x = frame.origin.x + xOffset

        let yOffset = touch.locationInView(nil).y - touch.previousLocationInView(nil).y
        let y = frame.origin.y + yOffset

        dragMenu(x, y: y)
    }

    private func dragMenu(x: CGFloat, y: CGFloat) {
        let outOfBounds = x < 0.0 || x >= superview!.frame.width - frame.width || y < 0.0 || y >= superview!.frame.height - frame.height
        if outOfBounds {
            touchesBeganTimestamp = nil
            return
        }

        UIView.animateWithDuration(0.0, delay: 0.0, options: .CurveLinear,
            animations: {
                self.frame.origin.x = x
                self.frame.origin.y = y
            },
            completion: { complete in
                print("viewfinder frame: \(self.frame)")
            }
        )
    }
}
