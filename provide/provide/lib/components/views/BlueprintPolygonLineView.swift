//
//  BlueprintPolygonLineView.swift
//  provide
//
//  Created by Kyle Thomas on 11/10/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class BlueprintPolygonLineView: UIView {

    private var startPoint: CGPoint!
    private var endPoint: CGPoint!

    private var lineLayer: CAShapeLayer!

    func setPoints(startPoint: CGPoint, endPoint: CGPoint) {
        self.startPoint = startPoint
        self.endPoint = endPoint

        if lineLayer == nil {
            lineLayer = CAShapeLayer()
            layer.addSublayer(lineLayer)
        }

        let path = UIBezierPath()
        path.moveToPoint(startPoint)
        path.addLineToPoint(endPoint)

        lineLayer.path = path.CGPath
        lineLayer.strokeColor = UIColor.blackColor().CGColor
        lineLayer.lineWidth = 2.0
        lineLayer.fillColor = UIColor.clearColor().CGColor

        sizeToFit()
    }
}
