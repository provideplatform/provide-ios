//
//  FloorplanScrollView.swift
//  provide
//
//  Created by Kyle Thomas on 11/10/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol FloorplanScrollViewDelegate {
    func floorplanTiledViewForFloorplanScrollView(scrollView: FloorplanScrollView) -> FloorplanTiledView!
}

class FloorplanScrollView: UIScrollView, UIGestureRecognizerDelegate {

    var floorplanScrollViewDelegate: FloorplanScrollViewDelegate!

    override var contentSize: CGSize {
        didSet {
            if let floorplanTiledView = floorplanScrollViewDelegate?.floorplanTiledViewForFloorplanScrollView(self) {
                //floorplanTiledView.center = center
                //floorplanTiledView.frame.size = contentSize
            }
        }
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
