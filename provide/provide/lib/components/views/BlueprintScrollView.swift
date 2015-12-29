//
//  BlueprintScrollView.swift
//  provide
//
//  Created by Kyle Thomas on 11/10/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol BlueprintScrollViewDelegate {

}

class BlueprintScrollView: UIScrollView, UIGestureRecognizerDelegate {

    var blueprintImageView: UIImageView! {
        var blueprintImageView: UIImageView!
        for subview in subviews {
            if subview.isKindOfClass(UIImageView) {
                blueprintImageView = subview as! UIImageView
                break
            }
        }
        return blueprintImageView
    }

    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.locationInView(self)
        if let view = hitTest(point, withEvent: nil) {
            for subview in view.subviews {
                if subview.isKindOfClass(UIImageView) {
                    for blueprintSubview in subview.subviews {
                        let pointInSubview = gestureRecognizer.locationInView(blueprintSubview)
                        if let v = blueprintSubview.hitTest(pointInSubview, withEvent: nil) {
                            if v.isKindOfClass(BlueprintPolygonVertexView) {
                                return false
                            }
                        }
                    }
                }
            }
        }
        return true
    }
}
