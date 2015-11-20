//
//  BlueprintPolygonView.swift
//  provide
//
//  Created by Kyle Thomas on 11/17/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol BlueprintPolygonViewDelegate {
    func blueprintScaleForBlueprintPolygonView(view: BlueprintPolygonView) -> CGFloat!
    func blueprintImageViewForBlueprintPolygonView(view: BlueprintPolygonView) -> UIImageView!
    func blueprintForBlueprintPolygonView(view: BlueprintPolygonView) -> Attachment!
    func blueprintPolygonViewDidClose(view: BlueprintPolygonView)
    func blueprintPolygonViewCanBeResized(view: BlueprintPolygonView) -> Bool
    func blueprintPolygonView(view: BlueprintPolygonView, colorForOverlayView overlayView: UIView) -> UIColor
    func blueprintPolygonView(view: BlueprintPolygonView, opacityForOverlayView overlayView: UIView) -> CGFloat
}

class BlueprintPolygonView: UIView, BlueprintPolygonVertexViewDelegate {

    var annotation: Annotation!

    var delegate: BlueprintPolygonViewDelegate! {
        didSet {
            if let _ = delegate {

            }
        }
    }

    var scale: CGFloat {
        if let blueprintScale = delegate?.blueprintScaleForBlueprintPolygonView(self) {
            return blueprintScale
        }
        return 1.0
    }

    var area: CGFloat! {
        didSet {
            if let area = area {
                if area != oldValue {
                    self.area = abs(area)
                }
            }
        }
    }

    var polygon: [[CGFloat]] {
        var polygonPoints = [[CGFloat]]()
        for point in points {
            polygonPoints.append([point.x, point.y])
        }
        return polygonPoints
    }

    private var points = [CGPoint]()

    private var pointViews = [BlueprintPolygonVertexView]()

    private var lineViews = [BlueprintPolygonLineView]()

    private var overlayView: UIView!

    private var isClosed: Bool {
        return points.count > 2 && (closePoint != nil || points.first!.x == points.last!.x && points.first!.y == points.last!.y)
    }

    private var closePoint: CGPoint!

    private var targetView: UIView! {
        if let superview = self.superview {
            return superview
        }
        return nil
    }

    required init(delegate: BlueprintPolygonViewDelegate, annotation: Annotation) {
        super.init(frame: CGRectZero)

        self.delegate = delegate
        self.annotation = annotation

        if let pts = annotation.polygon {
            for pt in pts {
                let point = CGPoint(x: pt[0], y: pt[1])
                addPoint(point)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func attachGestureRecognizer() {
        if let targetView = targetView {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: "pointSelected:")
            targetView.addGestureRecognizer(gestureRecognizer)
        }
    }

    private func removeGestureRecognizer() {
        if let targetView = targetView {
            targetView.removeGestureRecognizers()
        }
    }

    private func reset(suppressDelegateNotification: Bool = false) {
        points = [CGPoint]()

        removeGestureRecognizer()

        for pointView in pointViews {
            pointView.removeFromSuperview()
        }

        for lineView in lineViews {
            lineView.removeFromSuperview()
        }

        pointViews = [BlueprintPolygonVertexView]()
        lineViews = [BlueprintPolygonLineView]()

        if let overlayView = overlayView {
            overlayView.removeFromSuperview()
            self.overlayView = nil
        }

        closePoint = nil
    }

    func resignFirstResponder(suppressDelegateNotification: Bool = false) -> Bool {
        reset(suppressDelegateNotification)
        return super.resignFirstResponder()
    }

    func pointSelected(gestureRecognizer: UITapGestureRecognizer) {
        if isClosed {
            return
        }

        if let blueprintImageView = delegate?.blueprintImageViewForBlueprintPolygonView(self) {
            let point = gestureRecognizer.locationInView(blueprintImageView)

            var attemptPolygonCompletion = false

            if points.count > 2 {
                let firstPoint = points.first!

                let xDistance = abs(firstPoint.x - point.x)
                let yDistance = abs(firstPoint.y - point.y)
                let distance = sqrt((xDistance * xDistance) + (yDistance * yDistance))

                if distance <= 50.0 {
                    attemptPolygonCompletion = true
                }
            }

            if attemptPolygonCompletion {
                completePolygon()
            } else {
                addPoint(point)
            }
        }
    }

    private func addPoint(point: CGPoint) {
        if let blueprintImageView = delegate?.blueprintImageViewForBlueprintPolygonView(self) {
            points.append(point)

            let pointView = BlueprintPolygonVertexView(image: (UIImage(named: "map-pin")?.scaledToWidth(75.0))!)
            pointView.delegate = self
            pointView.frame.origin = CGPoint(x: point.x - (pointView.image!.size.width / 2.0),
                                             y: point.y - pointView.image!.size.height)
            
            if isClosed {
                closePoint = point

                pointView.alpha = 0.0
                pointView.userInteractionEnabled = false

                delegate?.blueprintPolygonViewDidClose(self)

                drawOverlayView()
            }

            pointViews.append(pointView)

            blueprintImageView.addSubview(pointView)
            blueprintImageView.bringSubviewToFront(pointView)

            drawLineSegment()
        }
    }

    private func drawOverlayView() {
        if let blueprintImageView = delegate?.blueprintImageViewForBlueprintPolygonView(self) {
            let overlayViewFrame = CGRectZero

            if overlayView == nil {
                overlayView = UIView(frame: overlayViewFrame)
                overlayView.layer.addSublayer(CAShapeLayer())

                blueprintImageView.addSubview(overlayView)
                blueprintImageView.bringSubviewToFront(overlayView)
            }

            if points.count > 0 {
                let path = UIBezierPath()

                path.moveToPoint(points[0])
                for point in points.dropFirst() {
                    path.addLineToPoint(point)
                }

                path.closePath()

                let layer = overlayView.layer.sublayers!.first! as! CAShapeLayer
                layer.path = path.CGPath

                if let delegate = delegate {
                    layer.opacity = Float(delegate.blueprintPolygonView(self, opacityForOverlayView: overlayView))
                    layer.fillColor = delegate.blueprintPolygonView(self, colorForOverlayView: overlayView).CGColor
                } else {
                    layer.opacity = 1.0
                    layer.fillColor = UIColor.clearColor().CGColor
                }

                overlayView.sizeToFit()
            }

        }
    }

    private func drawLineSegment() {
        if let blueprintImageView = delegate?.blueprintImageViewForBlueprintPolygonView(self) {
            let canDrawLine = points.count > 1

            if canDrawLine {
                let startPoint = points[points.count - 2]
                let endPoint = points[points.count - 1]

                let lineView = BlueprintPolygonLineView()
                lineView.setPoints(startPoint, endPoint: endPoint)
                lineViews.append(lineView)

                blueprintImageView.addSubview(lineView)
                blueprintImageView.bringSubviewToFront(lineView)

                for pointView in pointViews {
                    blueprintImageView.bringSubviewToFront(pointView)
                }

                if isClosed {
                    populateMeasurementFromCurrentScale()
                }
            }
        }
    }

    // MARK: BlueprintPolygonVertexViewDelegate

    func blueprintPolygonVertexViewShouldReceiveTouch(view: BlueprintPolygonVertexView) -> Bool {
        if let delegate = delegate {
             return delegate.blueprintPolygonViewCanBeResized(self)
        }
        return true
    }

    func blueprintPolygonVertexViewShouldRedrawVertices(view: BlueprintPolygonVertexView) { // FIXME -- poorly named method... maybe use Invalidated instead of ShouldRedraw...
        let index = pointViews.indexOf(view)!
        let lineViewIndex = isClosed && index == 0 ? lineViews.count - 1 : max(0, index - 1)

        points[index] = CGPoint(x: view.frame.origin.x + (view.image!.size.width / 2.0),
                                y: view.frame.origin.y + view.image!.size.height)

        if isClosed && (index == 0 || index == points.count - 1) {
            let i = index == 0 ? points.count - 1 : 0
            points[i] = points[index]
            pointViews[i].frame = view.frame
            closePoint = points[i]
        }

        if lineViews.count == 1 {
            let lineView = lineViews[0]
            lineView.setPoints(points[0], endPoint: points[1])
        } else if lineViews.count > 1 {
            let lineView = lineViews[lineViewIndex]
            lineView.moveEndpoint(points[index])

            if lineViews.count - 1 > lineViewIndex {
                let nextLineViewIndex = lineViewIndex + (!isClosed && index == 0 ? 0 : (isClosed && index == 0 ? 0 : 1))
                let nextLineView = lineViews[nextLineViewIndex]
                let nextPointIndex = points.count - 1 > index ? index + 1 : 0
                let nextPoint = points[nextPointIndex]

                nextLineView.setPoints(points[index], endPoint: nextPoint)
            } else if isClosed && lineViews.count - 1 == lineViewIndex {
                lineViews[0].setPoints(closePoint, endPoint: points[1])
            }
        }

        drawOverlayView()

        if isClosed {
            populateMeasurementFromCurrentScale()
        }
    }

    func blueprintPolygonVertexViewTapped(view: BlueprintPolygonVertexView) {
        if pointViews.indexOf(view)! == 0 {
            completePolygon()
        }
    }

    private func completePolygon() {
        if isClosed {
            return
        }

        addPoint(points.first!)
    }

    private func populateMeasurementFromCurrentScale() {
        if !isClosed {
            return
        }

        let mapPoints = UnsafeMutablePointer<MKMapPoint>.alloc(points.count)
        var i = 0
        for point in points {
            mapPoints[i++] = MKMapPoint(x: Double(point.x), y: Double(point.y))
        }

        let polygon = MKPolygon(points: mapPoints, count: points.count)
        area = polygon.area / (scale * scale)
    }
}
