//
//  MenuTableView.swift
//  provide
//
//  Created by Kyle Thomas on 7/25/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class MenuTableView: UITableView {

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)

        if shouldPassTouchToSuperview(touches.first!) {
            superview!.touchesBegan(touches, withEvent: event)
        }
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)

        if shouldPassTouchToSuperview(touches.first!) {
            superview!.touchesEnded(touches, withEvent: event)
        }
    }

    override func touchesCancelled(touches: Set<UITouch>!, withEvent event: UIEvent!) {
        super.touchesCancelled(touches, withEvent: event)

        if shouldPassTouchToSuperview(touches.first!) {
            superview!.touchesCancelled(touches, withEvent: event)
        }
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)

        if shouldPassTouchToSuperview(touches.first!) {
            superview!.touchesMoved(touches, withEvent: event)
        }
    }

    private func shouldPassTouchToSuperview(touch: UITouch) -> Bool {
        if let _ = indexPathForRowAtPoint(touch.locationInView(self)) {
            return false
        }

        return true
    }
}
