//
//  FloorplanThumbnailOverlayView.swift
//  provide
//
//  Created by Kyle Thomas on 10/24/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol FloorplanThumbnailOverlayViewDelegate: NSObjectProtocol {
    func floorplanThumbnailOverlayViewNavigationBegan(_ view: FloorplanThumbnailOverlayView)
    func floorplanThumbnailOverlayViewNavigationEnded(_ view: FloorplanThumbnailOverlayView)
    func floorplanThumbnailOverlayView(_ view: FloorplanThumbnailOverlayView, navigatedToFrame frame: CGRect)
}

class FloorplanThumbnailOverlayView: UIView {

    weak var delegate: FloorplanThumbnailOverlayViewDelegate!

    fileprivate var touchesBeganTimestamp: Date!

    fileprivate var gestureInProgress: Bool {
        return touchesBeganTimestamp != nil
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        delegate?.floorplanThumbnailOverlayViewNavigationBegan(self)

        touchesBeganTimestamp = Date()
        applyTouches(touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        delegate?.floorplanThumbnailOverlayViewNavigationEnded(self)

        applyTouches(touches)
        touchesBeganTimestamp = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)

        delegate?.floorplanThumbnailOverlayViewNavigationEnded(self)

        touchesBeganTimestamp = nil
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        applyTouches(touches)
    }

    fileprivate func applyTouches(_ touches: Set<UITouch>) {
        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0

        for touch in touches {
            xOffset += touch.location(in: nil).x - touch.previousLocation(in: nil).x
            yOffset += touch.location(in: nil).y - touch.previousLocation(in: nil).y

            dragOverlay(xOffset, yOffset: yOffset)
        }
    }

    fileprivate func dragOverlay(_ xOffset: CGFloat, yOffset: CGFloat) {
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

        delegate?.floorplanThumbnailOverlayView(self, navigatedToFrame: frame)
    }
}
