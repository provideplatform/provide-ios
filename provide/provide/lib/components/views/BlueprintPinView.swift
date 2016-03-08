//
//  BlueprintPinView.swift
//  provide
//
//  Created by Kyle Thomas on 3/7/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol BlueprintPinViewDelegate: NSObjectProtocol {
    func blueprintImageViewForBlueprintPinView(view: BlueprintPinView) -> UIImageView!
    func blueprintPinViewWasSelected(view: BlueprintPinView)

//    func blueprintForBlueprintPolygonView(view: BlueprintPolygonView) -> Attachment!
//    func blueprintPolygonViewDidClose(view: BlueprintPolygonView)
//    func blueprintPolygonViewCanBeResized(view: BlueprintPolygonView) -> Bool
//    func blueprintPolygonView(view: BlueprintPolygonView, colorForOverlayView overlayView: UIView) -> UIColor
//    func blueprintPolygonView(view: BlueprintPolygonView, opacityForOverlayView overlayView: UIView) -> CGFloat
//    func blueprintPolygonView(view: BlueprintPolygonView, layerForOverlayView overlayView: UIView, inBoundingBox boundingBox: CGRect) -> CALayer!
//    func blueprintPolygonView(view: BlueprintPolygonView, didSelectOverlayView overlayView: UIView, atPoint point: CGPoint, inPath path: CGPath)
//    func blueprintPolygonView(view: BlueprintPolygonView, didUpdateAnnotation annotation: Annotation)
}

class BlueprintPinView: UIImageView, UIGestureRecognizerDelegate {

    var annotation: Annotation!

    weak var delegate: BlueprintPinViewDelegate! {
        didSet {
            if let _ = delegate {

            }
        }
    }

    var point: CGPoint!

    private var gestureRecognizer: UITapGestureRecognizer!

    private var timer: NSTimer!

    private var blueprintImageView: UIImageView! {
        if let blueprintImageView = delegate?.blueprintImageViewForBlueprintPinView(self) {
            return blueprintImageView
        } else {
            return nil
        }
    }

    private var targetView: UIView! {
        if let superview = self.superview {
            return superview
        }
        return nil
    }

    required init(annotation: Annotation) {
        super.init(frame: CGRectZero)

        self.annotation = annotation

        if let point = annotation.point {
            self.point = CGPoint(x: point[0], y: point[1])
        }

        image = UIImage(named: "map-pin")!.scaledToWidth(75.0)
        bounds = CGRect(x: 0.0, y: 0.0, width: image!.size.width, height: image!.size.height)
    }

    required init(delegate: BlueprintPinViewDelegate, annotation: Annotation) {
        super.init(frame: CGRectZero)

        self.delegate = delegate
        self.annotation = annotation

        if let point = annotation.point {
            self.point = CGPoint(x: point[0], y: point[1])
        }

        image = UIImage(named: "map-pin")!.scaledToWidth(75.0)
        bounds = CGRect(x: 0.0, y: 0.0, width: image!.size.width, height: image!.size.height)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func attachGestureRecognizer() {
        if let targetView = targetView {
            gestureRecognizer = UITapGestureRecognizer(target: self, action: "pinSelected:")
            targetView.addGestureRecognizer(gestureRecognizer)
        }
    }

    private func removeGestureRecognizer() {
        if let targetView = targetView {
            if let gestureRecognizer = gestureRecognizer {
                targetView.removeGestureRecognizer(gestureRecognizer)
                self.gestureRecognizer = nil
            }
        }
    }

    private func reset(suppressDelegateNotification: Bool = false) {
        point = nil

        removeGestureRecognizer()
    }

    func resignFirstResponder(suppressDelegateNotification: Bool = false) -> Bool {
        reset(suppressDelegateNotification)
        return super.resignFirstResponder()
    }

    func pinSelected(gestureRecognizer: UITapGestureRecognizer) {
        if let _ = blueprintImageView {
            delegate?.blueprintPinViewWasSelected(self)
        }
    }

    func redraw() {
        reset()
        attachGestureRecognizer()
    }
}
