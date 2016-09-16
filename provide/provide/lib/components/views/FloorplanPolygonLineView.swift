//
//  FloorplanPolygonLineView.swift
//  provide
//
//  Created by Kyle Thomas on 11/10/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class FloorplanPolygonLineView: UIView {

    fileprivate var startPoint: CGPoint!
    fileprivate var endPoint: CGPoint!

    fileprivate var lineLayer: CAShapeLayer!

    func setPoints(_ startPoint: CGPoint, endPoint: CGPoint) {
        self.startPoint = startPoint
        self.endPoint = endPoint

        if lineLayer == nil {
            lineLayer = CAShapeLayer()
            layer.addSublayer(lineLayer)
        }

        let path = UIBezierPath()
        path.move(to: startPoint)
        path.addLine(to: endPoint)

        lineLayer.path = path.cgPath
        lineLayer.strokeColor = UIColor.black.cgColor
        lineLayer.lineWidth = 2.0
        lineLayer.fillColor = UIColor.clear.cgColor

        sizeToFit()
    }

    func moveEndpoint(_ point: CGPoint) {
        setPoints(startPoint, endPoint: point)
    }
}
