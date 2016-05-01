//
//  BlueprintPolygonVertexViewGestureRecognizer.swift
//  provide
//
//  Created by Kyle Thomas on 11/10/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

class BlueprintPolygonVertexViewGestureRecognizer: UIGestureRecognizer {

    private var touchesBeganTimestamp: NSDate!

    private var gestureInProgress: Bool {
        return touchesBeganTimestamp != nil
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)

        state = .Began

        touchesBeganTimestamp = NSDate()
        applyTouches(touches)
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)

        state = .Ended

        applyTouches(touches)
        touchesBeganTimestamp = nil
    }

    override func touchesCancelled(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesCancelled(touches, withEvent: event)

        state = .Cancelled
        
        touchesBeganTimestamp = nil
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        applyTouches(touches)
    }

    private func applyTouches(touches: Set<UITouch>) {
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0

        for touch in touches {
            xOffset += touch.locationInView(nil).x - touch.previousLocationInView(nil).x
            yOffset += touch.locationInView(nil).y - touch.previousLocationInView(nil).y

            dragVertex(xOffset, yOffset: yOffset)
        }
    }

    private func dragVertex(xOffset: CGFloat, yOffset: CGFloat) {
        var xOffset = xOffset
        var yOffset = yOffset
        if let view = view {
            if let superview = view.superview?.superview {
                if superview is BlueprintScrollView {
                    let zoomScale = (superview as! BlueprintScrollView).zoomScale
                    if zoomScale < 1.0 {
                        xOffset = xOffset * (2.0 - zoomScale)
                        yOffset = yOffset * (2.0 - zoomScale)
                    }
                }
            }

            var newFrame = CGRect(origin: view.frame.origin, size: view.frame.size)
            newFrame.origin.x += xOffset
            newFrame.origin.y += yOffset

            let x = newFrame.origin.x
            let y = newFrame.origin.y

            if x < 0.0 {
                newFrame.origin.x = 0.0
            }

            if y < 0.0 {
                newFrame.origin.y = 0.0
            }

            view.frame = newFrame
        }
    }
}
