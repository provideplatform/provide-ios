//
//  DraggableViewGestureRecognizer.swift
//  provide
//
//  Created by Kyle Thomas on 12/14/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

@objc
protocol DraggableViewGestureRecognizerDelegate {
    optional func draggableViewGestureRecognizer(gestureRecognizer: DraggableViewGestureRecognizer, shouldResetView view: UIView) -> Bool
    optional func draggableViewGestureRecognizer(gestureRecognizer: DraggableViewGestureRecognizer, shouldAnimateResetView view: UIView) -> Bool
}

class DraggableViewGestureRecognizer: UIGestureRecognizer {

    var draggableViewGestureRecognizerDelegate: DraggableViewGestureRecognizerDelegate!

    internal var touchesBeganTimestamp: NSDate!
    internal var initialView: UIView!
    internal var initialSuperview: UIView!
    internal var initialFrame: CGRect!
    internal var initialAlpha: CGFloat!

    private var superviewChanged: Bool {
        if let initialView = initialView {
            if let initialSuperview = initialSuperview {
                return initialView.superview != initialSuperview
            }
        }
        return false
    }

    private var gestureInProgress: Bool {
        return touchesBeganTimestamp != nil
    }

    private func cleanup() {
        initialView = nil
        initialSuperview = nil
        initialFrame = nil
        initialAlpha = nil
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent) {
        let view = touches.first!.view!
        if let superview = view.superview {
            initialSuperview = superview
            if superview.isKindOfClass(UICollectionViewCell) {
                while !initialSuperview.isKindOfClass(UICollectionView) {
                    initialSuperview = initialSuperview.superview!
                }
                initialView = superview
            } else if superview.superview!.isKindOfClass(UICollectionViewCell) {
                while !initialSuperview.isKindOfClass(UICollectionView) {
                    initialSuperview = initialSuperview.superview!
                }
                initialView = superview.superview!
            } else {
                initialView = view
            }
        } else {
            initialView = view
        }
        initialFrame = initialView.frame
        initialAlpha = initialView.alpha

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

        if let shouldResetView = draggableViewGestureRecognizerDelegate?.draggableViewGestureRecognizer?(self, shouldResetView: initialView) {
            if shouldResetView {
                var duration = 0.3
                var delay = 0.1
                if let shouldAnimate = draggableViewGestureRecognizerDelegate?.draggableViewGestureRecognizer?(self, shouldAnimateResetView: initialView) {
                    if !shouldAnimate {
                        duration = 0.0
                        delay = 0.0
                    }
                }
                UIView.animateWithDuration(duration, delay: delay, options: .CurveEaseOut,
                    animations: { [weak self] in
                        self!.initialView.frame = self!.initialFrame
                        self!.initialView.alpha = self!.initialAlpha
                    },
                    completion: { [weak self] complete in
                        if self!.superviewChanged {
                            let window = UIApplication.sharedApplication().keyWindow!
                            self!.initialView.removeFromSuperview()

                            self!.initialView.frame = window.convertRect(self!.initialView.frame, toView: self!.initialSuperview)
                            self!.initialView.alpha = self!.initialAlpha
                            self!.initialSuperview.addSubview(self!.initialView)
                            self!.initialSuperview.bringSubviewToFront(self!.initialView)
                        }

                        self!.cleanup()
                    }
                )
            } else {
                cleanup()
            }
        } else {
            cleanup()
        }
    }

    override func touchesCancelled(touches: Set<UITouch>, withEvent event: UIEvent) {
        super.touchesCancelled(touches, withEvent: event)

        state = .Cancelled

        touchesBeganTimestamp = nil

        cleanup()
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

            drag(xOffset, yOffset: yOffset)
        }
    }

    internal func drag(xOffset: CGFloat, yOffset: CGFloat) {
        if let view = view {
            drag(view, xOffset: xOffset, yOffset: yOffset)
        }
    }

    internal func drag(view: UIView, xOffset: CGFloat, yOffset: CGFloat) {
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
