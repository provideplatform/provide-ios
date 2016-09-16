//
//  FloorplanPolygonVertexViewGestureRecognizer.swift
//  provide
//
//  Created by Kyle Thomas on 11/10/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

class FloorplanPolygonVertexViewGestureRecognizer: UIGestureRecognizer {

    fileprivate var touchesBeganTimestamp: Date!

    fileprivate var gestureInProgress: Bool {
        return touchesBeganTimestamp != nil
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)

        state = .began

        touchesBeganTimestamp = Date()
        applyTouches(touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)

        state = .ended

        applyTouches(touches)
        touchesBeganTimestamp = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)

        state = .cancelled
        
        touchesBeganTimestamp = nil
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        applyTouches(touches)
    }

    fileprivate func applyTouches(_ touches: Set<UITouch>) {
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0

        for touch in touches {
            xOffset += touch.location(in: nil).x - touch.previousLocation(in: nil).x
            yOffset += touch.location(in: nil).y - touch.previousLocation(in: nil).y

            dragVertex(xOffset, yOffset: yOffset)
        }
    }

    fileprivate func dragVertex(_ xOffset: CGFloat, yOffset: CGFloat) {
        var xOffset = xOffset
        var yOffset = yOffset
        if let view = view {
            if let superview = view.superview?.superview {
                if superview is FloorplanScrollView {
                    let zoomScale = (superview as! FloorplanScrollView).zoomScale
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
