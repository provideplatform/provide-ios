//
//  NavigationBarButton.swift
//  provide
//
//  Created by Kyle Thomas on 7/26/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class NavigationBarButton: UIButton {

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    class func barButtonItemWithImage(image: UIImage, target: AnyObject?, action: String, tintColor: UIColor = Color.applicationDefaultBarButtonItemTintColor()) -> UIBarButtonItem {
        let button = NavigationBarButton(type: .Custom)
        button.frame = CGRect(x: 0.0, y: 0.0, width: image.size.width, height: image.size.height)
        button.setImage(image.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        button.tintColor = tintColor
        button.addTarget(target, action: Selector(action), forControlEvents: .TouchUpInside)

        return UIBarButtonItem(customView: button)
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)

        selected = true

        if shouldPassTouchToSuperview(touches.first!) {
            superview!.touchesBegan(touches, withEvent: event)
        }
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)

        selected = false

        if shouldPassTouchToSuperview(touches.first!) {
            superview!.touchesEnded(touches, withEvent: event)
        }
    }

    override func touchesCancelled(touches: Set<UITouch>!, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)

        selected = false

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
        return false
    }

}
