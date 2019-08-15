//
//  MenuTableView.swift
//  provide
//
//  Created by Kyle Thomas on 7/25/15.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import UIKit

class MenuTableView: UITableView {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        if shouldPassTouchToSuperview(touches.first!) {
            superview!.touchesBegan(touches, with: event)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        if shouldPassTouchToSuperview(touches.first!) {
            superview!.touchesEnded(touches, with: event)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent!) {
        super.touchesCancelled(touches, with: event)

        if shouldPassTouchToSuperview(touches.first!) {
            superview!.touchesCancelled(touches, with: event)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)

        if shouldPassTouchToSuperview(touches.first!) {
            superview!.touchesMoved(touches, with: event)
        }
    }

    private func shouldPassTouchToSuperview(_ touch: UITouch) -> Bool {
        if indexPathForRow(at: touch.location(in: self)) != nil {
            return false
        }

        return true
    }
}
