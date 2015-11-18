//
//  MKPolygonExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 11/18/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import MapKit

extension MKPolygon {

    class func areaWithPoints(points: [CGPoint]) -> CGFloat {
        if points.count < 3 {
            return 0.0
        }

        var result: CGFloat = 0.0

        var previousPoint = points[points.count - 1]

        for point in points {
            result += (previousPoint.x * point.y) - (previousPoint.y * point.x)
            previousPoint = point
        }
        
        return result / 2.0
    }

    var area: CGFloat {
        var points = [CGPoint]()

        for i in 0..<pointCount {
            let point = self.points()[i]
            points.append(CGPoint(x: point.x, y: point.y))
        }

        var result = MKPolygon.areaWithPoints(points)

        for interior in interiorPolygons! {
            result -= interior.area
        }
        
        return result
    }

}
