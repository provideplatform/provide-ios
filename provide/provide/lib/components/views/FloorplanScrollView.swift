//
//  FloorplanScrollView.swift
//  provide
//
//  Created by Kyle Thomas on 11/10/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol FloorplanScrollViewDelegate {
    func floorplanTiledViewForFloorplanScrollView(_ scrollView: FloorplanScrollView) -> FloorplanTiledView!
}

class FloorplanScrollView: UIScrollView, UIGestureRecognizerDelegate {

    var floorplanScrollViewDelegate: FloorplanScrollViewDelegate!

    override var contentSize: CGSize {
        didSet {
            if let _ = floorplanScrollViewDelegate?.floorplanTiledViewForFloorplanScrollView(self) {
                //floorplanTiledView.center = center
                //floorplanTiledView.frame.size = contentSize
            }
        }
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.location(in: self)
        if let view = hitTest(point, with: nil) {
            for subview in view.subviews {
                if subview.isKind(of: UIImageView.self) {
                    for floorplanSubview in subview.subviews {
                        let pointInSubview = gestureRecognizer.location(in: floorplanSubview)
                        if let v = floorplanSubview.hitTest(pointInSubview, with: nil) {
                            if v.isKind(of: FloorplanPolygonVertexView.self) || v.isKind(of: FloorplanPinView.self) {
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
