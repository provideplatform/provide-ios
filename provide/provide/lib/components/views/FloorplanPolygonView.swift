//
//  FloorplanPolygonView.swift
//  provide
//
//  Created by Kyle Thomas on 11/17/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

protocol FloorplanPolygonViewDelegate: NSObjectProtocol {
    func floorplanScaleForFloorplanPolygonView(_ view: FloorplanPolygonView) -> CGFloat!
    func floorplanImageViewForFloorplanPolygonView(_ view: FloorplanPolygonView) -> UIImageView!
    func floorplanForFloorplanPolygonView(_ view: FloorplanPolygonView) -> Attachment!
    func floorplanPolygonViewDidClose(_ view: FloorplanPolygonView)
    func floorplanPolygonViewCanBeResized(_ view: FloorplanPolygonView) -> Bool
    func floorplanPolygonView(_ view: FloorplanPolygonView, colorForOverlayView overlayView: UIView) -> UIColor
    func floorplanPolygonView(_ view: FloorplanPolygonView, opacityForOverlayView overlayView: UIView) -> CGFloat
    func floorplanPolygonView(_ view: FloorplanPolygonView, layerForOverlayView overlayView: UIView, inBoundingBox boundingBox: CGRect) -> CALayer!
    func floorplanPolygonView(_ view: FloorplanPolygonView, didSelectOverlayView overlayView: UIView, atPoint point: CGPoint, inPath path: CGPath)
    func floorplanPolygonView(_ view: FloorplanPolygonView, didUpdateAnnotation annotation: Annotation)
}

class FloorplanPolygonView: UIView, FloorplanPolygonVertexViewDelegate, UIGestureRecognizerDelegate {

    var annotation: Annotation!

    weak var delegate: FloorplanPolygonViewDelegate! {
        didSet {
            if let _ = delegate {

            }
        }
    }

    var scale: CGFloat {
        if let floorplanScale = delegate?.floorplanScaleForFloorplanPolygonView(self) {
            return floorplanScale
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

    var previewImage: UIImage! {
        if let overlayViewBoundingBox = overlayViewBoundingBox {
            if let floorplanImageView = floorplanImageView {
                return floorplanImageView.image!.crop(overlayViewBoundingBox)

//                if let superview = floorplanImageView.superview as? FloorplanScrollView {
//                    let dx = overlayViewBoundingBox.width / 2.0
//                    let dy = overlayViewBoundingBox.height / 2.0
//                    let translatedRect = superview.convertRect(cropRect, toView: superview.superview)
//                    print("translated rect: \(translatedRect)")
//
//
//
//                    let image = superview.toImage()
//                    print("captured image size: \(image.size)")
//                    let croppedImage = image.crop(translatedRect)
//                    print("cropped image size: \(croppedImage.size)")
//
//                    return croppedImage
//                }
            }
        }
        return nil
    }

    var overlayViewPreviewImage: UIImage! {
        if let overlayViewBoundingBox = overlayViewBoundingBox {
            if let floorplanImageView = floorplanImageView {
                return floorplanImageView.image!.crop(overlayViewBoundingBox)
            }
        }
        return nil
    }

    var overlayViewBoundingBox: CGRect! {
        if let overlayView = overlayView {
            if let layer = overlayView.layer.sublayers!.first as? CAShapeLayer {
                return (layer.path)!.boundingBoxOfPath
            }
        }
        return nil
    }

    fileprivate var floorplanImageView: UIImageView! {
        if let floorplanImageView = delegate?.floorplanImageViewForFloorplanPolygonView(self) {
            return floorplanImageView
        } else {
            return nil
        }
    }

    fileprivate var points = [CGPoint]()

    fileprivate var pointViews = [FloorplanPolygonVertexView]()

    fileprivate var lineViews = [FloorplanPolygonLineView]()

    fileprivate var overlayView: UIView!

    fileprivate var gestureRecognizer: UITapGestureRecognizer!

    fileprivate var timer: Timer!

    fileprivate var isClosed: Bool {
        return points.count > 2 && (closePoint != nil || points.first!.x == points.last!.x && points.first!.y == points.last!.y)
    }

    fileprivate var closePoint: CGPoint!

    fileprivate var targetView: UIView! {
        if let superview = self.superview {
            return superview
        }
        return nil
    }

    required init(annotation: Annotation) {
        super.init(frame: CGRect.zero)

        self.annotation = annotation

        if let pts = annotation.polygon {
            for pt in pts {
                let point = CGPoint(x: pt[0], y: pt[1])
                addPoint(point)
            }
        }
    }

    required init(delegate: FloorplanPolygonViewDelegate, annotation: Annotation) {
        super.init(frame: CGRect.zero)

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
        if floorplanImageView == nil {
            return
        }
        if let targetView = targetView {
            gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(FloorplanPolygonView.pointSelected(_:)))
            gestureRecognizer.delegate = self
            targetView.addGestureRecognizer(gestureRecognizer)
        }
    }

    fileprivate func removeGestureRecognizer() {
        if let targetView = targetView {
            if let gestureRecognizer = gestureRecognizer {
                targetView.removeGestureRecognizer(gestureRecognizer)
                self.gestureRecognizer = nil
            }
        }
    }

    fileprivate func reset(_ suppressDelegateNotification: Bool = false) {
        points = [CGPoint]()

        removeGestureRecognizer()

        for pointView in pointViews {
            pointView.removeFromSuperview()
        }

        for lineView in lineViews {
            lineView.removeFromSuperview()
        }

        pointViews = [FloorplanPolygonVertexView]()
        lineViews = [FloorplanPolygonLineView]()

        if let overlayView = overlayView {
            overlayView.removeFromSuperview()
            self.overlayView = nil
        }

        closePoint = nil
    }

    func resignFirstResponder(_ suppressDelegateNotification: Bool = false) -> Bool {
        reset(suppressDelegateNotification)
        return super.resignFirstResponder()
    }

    func overlaySelected(_ gestureRecognizer: UITapGestureRecognizer) {
        if isClosed {
            if let floorplanImageView = floorplanImageView {
                let point = gestureRecognizer.location(in: floorplanImageView)
                let layer = overlayView.layer.sublayers!.first! as! CAShapeLayer
                let path = layer.path!
                if path.contains(point) {
                    delegate?.floorplanPolygonView(self, didSelectOverlayView: overlayView, atPoint: point, inPath: path)
                }
            }
        }
    }

    func pointSelected(_ gestureRecognizer: UITapGestureRecognizer) {
        if isClosed {
            overlaySelected(gestureRecognizer)
            return
        }

        if let floorplanImageView = floorplanImageView {
            let point = gestureRecognizer.location(in: floorplanImageView)

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

    func redraw() {
        dispatch_after_delay(0.0) {
            self.reset()
            if let pts = self.annotation.polygon {
                for pt in pts {
                    let point = CGPoint(x: pt[0], y: pt[1])
                    self.addPoint(point)
                }
            }
            self.attachGestureRecognizer()
        }
    }

    fileprivate func addPoint(_ point: CGPoint) {
        let pointSuperview = floorplanImageView != nil ? floorplanImageView : self

        points.append(point)

        let pointView = FloorplanPolygonVertexView(image: (UIImage(named: "map-pin")?.scaledToWidth(75.0))!)
        pointView.delegate = self
        pointView.alpha = delegate != nil ? (delegate!.floorplanPolygonViewCanBeResized(self) ? 1.0 : 0.0) : 0.0
        pointView.frame.origin = CGPoint(x: point.x - (pointView.image!.size.width / 2.0),
                                         y: point.y - pointView.image!.size.height)

        if isClosed {
            closePoint = point

            pointView.alpha = 0.0
            pointView.isUserInteractionEnabled = false

            delegate?.floorplanPolygonViewDidClose(self)

            populateMeasurementFromCurrentScale()
            drawOverlayView(pointSuperview)
        }

        pointViews.append(pointView)

        pointSuperview.addSubview(pointView)
        pointSuperview.bringSubview(toFront: pointView)

        drawLineSegment(pointSuperview)
    }

    fileprivate func drawOverlayView(_ view: UIView) {
        //            let overlayViewFrame = CGRectZero

        if overlayView == nil {
            overlayView = UIView(frame: CGRect.zero)
            overlayView.layer.addSublayer(CAShapeLayer())
            overlayView.layer.addSublayer(CALayer())

            view.addSubview(overlayView)
            view.bringSubview(toFront: overlayView)
        } else {
            overlayView.frame = CGRect(x: 0.0,
                                       y: 0.0,
                                       width: overlayViewBoundingBox.width,
                                       height: overlayViewBoundingBox.height)
            frame = overlayView.frame
        }

        if points.count > 0 {
            let path = UIBezierPath()

            path.move(to: points[0])
            for point in points.dropFirst() {
                path.addLine(to: point)
            }

            path.close()

            let layer = overlayView.layer.sublayers!.first! as! CAShapeLayer
            layer.path = path.cgPath

            if let delegate = delegate {
                layer.opacity = Float(delegate.floorplanPolygonView(self, opacityForOverlayView: overlayView))
                layer.fillColor = delegate.floorplanPolygonView(self, colorForOverlayView: overlayView).cgColor
            } else {
                layer.opacity = 1.0
                layer.fillColor = UIColor.clear.cgColor
            }

            if let sublayer = delegate?.floorplanPolygonView(self, layerForOverlayView: overlayView, inBoundingBox: ((layer.path)?.boundingBoxOfPath)!) {
                overlayView.layer.replaceSublayer(overlayView.layer.sublayers!.last!, with: sublayer)
            }
        }
    }

    fileprivate func drawLineSegment(_ view: UIView) {
        let canDrawLine = points.count > 1

        if canDrawLine {
            let startPoint = points[points.count - 2]
            let endPoint = points[points.count - 1]

            let lineView = FloorplanPolygonLineView()
            lineView.setPoints(startPoint, endPoint: endPoint)
            lineViews.append(lineView)

            view.addSubview(lineView)
            view.bringSubview(toFront: lineView)

            for pointView in pointViews {
                view.bringSubview(toFront: pointView)
            }

            if isClosed {
                populateMeasurementFromCurrentScale()
            }
        }
    }

    // MARK: FloorplanPolygonVertexViewDelegate

    func floorplanPolygonVertexViewShouldReceiveTouch(_ view: FloorplanPolygonVertexView) -> Bool {
        if let delegate = delegate {
             return delegate.floorplanPolygonViewCanBeResized(self)
        }
        return true
    }

    func floorplanPolygonVertexViewShouldRedrawVertices(_ view: FloorplanPolygonVertexView) { // FIXME -- poorly named method... maybe use Invalidated instead of ShouldRedraw...
        let pointSuperview = floorplanImageView != nil ? floorplanImageView : self

        cancelAnnotationUpdate()

        let index = pointViews.index(of: view)!
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

        if isClosed {
            populateMeasurementFromCurrentScale()
            drawOverlayView(pointSuperview)
            scheduleAnnotationUpdate()
        }
    }

    func floorplanPolygonVertexViewTapped(_ view: FloorplanPolygonVertexView) {
        if pointViews.index(of: view)! == 0 {
            completePolygon()
        }
    }

    fileprivate func cancelAnnotationUpdate() {
        if let timer = timer {
            timer.invalidate()
            self.timer = nil
        }
    }

    fileprivate func scheduleAnnotationUpdate() {
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(FloorplanPolygonView.updateAnnotation), userInfo: nil, repeats: false)
    }

    func updateAnnotation() {
        timer = nil

//        if let annotation = annotation {
//            if let attachment = delegate?.floorplanForFloorplanPolygonView(self) {
//                annotation.polygon = polygon
//                annotation.save(attachment,
//                    onSuccess: { statusCode, mappingResult in
//                        self.delegate?.floorplanPolygonView(self, didUpdateAnnotation: annotation)
//                    },
//                    onError: { error, statusCode, responseString in
//
//                    }
//                )
//            }
//        }
    }

    fileprivate func completePolygon() {
        if isClosed {
            return
        }

        addPoint(points.first!)
    }

    fileprivate func populateMeasurementFromCurrentScale() {
        if !isClosed {
            return
        }

        let mapPoints = UnsafeMutablePointer<MKMapPoint>.allocate(capacity: points.count)
        var i = 0
        for point in points {
            mapPoints[i] = MKMapPoint(x: Double(point.x), y: Double(point.y))
            i += 1
        }

        let polygon = MKPolygon(points: mapPoints, count: points.count)
        area = polygon.area / (scale * scale)
    }

    // MARK: UIGestureRecognizerDelegate

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if isClosed {
            if let floorplanImageView = floorplanImageView {
                let point = gestureRecognizer.location(in: floorplanImageView)
                let layer = overlayView.layer.sublayers!.first! as! CAShapeLayer
                let path = layer.path!
                return path.contains(point)
            }
        }
        return true
    }
}
