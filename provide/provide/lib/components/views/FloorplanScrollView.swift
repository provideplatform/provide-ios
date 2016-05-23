//
//  FloorplanScrollView.swift
//  provide
//
//  Created by Kyle Thomas on 11/10/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol FloorplanScrollViewDelegate {

}

class FloorplanScrollView: UIScrollView, UIGestureRecognizerDelegate {

    var floorplanImageView: UIImageView! {
        var floorplanImageView: UIImageView!
        for subview in subviews {
            if subview.isKindOfClass(UIImageView) {
                floorplanImageView = subview as! UIImageView
                break
            }
        }
        return floorplanImageView
    }

    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.locationInView(self)
        if let view = hitTest(point, withEvent: nil) {
            for subview in view.subviews {
                if subview.isKindOfClass(UIImageView) {
                    for floorplanSubview in subview.subviews {
                        let pointInSubview = gestureRecognizer.locationInView(floorplanSubview)
                        if let v = floorplanSubview.hitTest(pointInSubview, withEvent: nil) {
                            if v.isKindOfClass(FloorplanPolygonVertexView) || v.isKindOfClass(FloorplanPinView) {
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
