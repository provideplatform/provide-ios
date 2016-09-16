//
//  FloorplanScaleView.swift
//  provide
//
//  Created by Kyle Thomas on 11/10/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

protocol FloorplanScaleViewDelegate {
    func floorplanImageViewForFloorplanScaleView(_ view: FloorplanScaleView) -> UIImageView!
    func floorplanScaleForFloorplanScaleView(_ view: FloorplanScaleView) -> CGFloat
    func floorplanScaleViewCanSetFloorplanScale(_ view: FloorplanScaleView)
    func floorplanScaleView(_ view: FloorplanScaleView, didSetScale scale: CGFloat)
    func floorplanScaleViewDidReset(_ view: FloorplanScaleView)
}

class FloorplanScaleView: UIView, FloorplanPolygonVertexViewDelegate, UITextFieldDelegate {

    var delegate: FloorplanScaleViewDelegate! {
        didSet {
            if let _ = delegate {
                measurementTextField.text = ""
                instructionLabel.text = "Tap the location from which measuring began"
            }
        }
    }

    var distance: CGFloat {
        let xDistance = abs(secondPoint.x - firstPoint.x)
        let yDistance = abs(secondPoint.y - firstPoint.y)
        return sqrt((xDistance * xDistance) + (yDistance * yDistance))
    }

    var scale: CGFloat {
        if let measurementText = measurementTextField.text {
            if measurementText.length > 0 {
                let measuredDistance = CGFloat(Float(measurementText)!)
                return distance / measuredDistance
            }
        }
        return 1.0
    }

    @IBOutlet fileprivate weak var instructionLabel: UILabel!
    @IBOutlet fileprivate weak var measurementTextField: UITextField!
    @IBOutlet fileprivate weak var saveButton: UIButton! {
        didSet {
            if let saveButton = saveButton {
                saveButton.isHidden = true
                saveButton.addTarget(self, action: #selector(FloorplanScaleView.setScale), for: .touchUpInside)
            }
        }
    }

    fileprivate var firstPoint: CGPoint!
    fileprivate var secondPoint: CGPoint!

    fileprivate var firstPointView: FloorplanPolygonVertexView!
    fileprivate var secondPointView: FloorplanPolygonVertexView!

    fileprivate var lineView: FloorplanPolygonLineView!

    fileprivate var targetView: UIView! {
        if let superview = self.superview {
            return superview
        }
        return nil
    }

    func setScale() {
        delegate?.floorplanScaleView(self, didSetScale: scale)
    }

    func attachGestureRecognizer() {
        if let targetView = targetView {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(FloorplanScaleView.pointSelected(_:)))
            targetView.addGestureRecognizer(gestureRecognizer)
        }
    }

    fileprivate func removeGestureRecognizer() {
        if let targetView = targetView {
            targetView.removeGestureRecognizers()
        }
    }

    fileprivate func reset(_ suppressDelegateNotification: Bool = false) {
        firstPoint = nil
        secondPoint = nil

        removeGestureRecognizer()

        if let measurementTextField = measurementTextField {
            if measurementTextField.isFirstResponder {
                measurementTextField.resignFirstResponder()
            }
        }

        if let firstPointView = firstPointView {
            firstPointView.removeFromSuperview()
        }

        if let secondPointView = secondPointView {
            secondPointView.removeFromSuperview()
        }

        if let lineView = lineView {
            lineView.removeFromSuperview()
        }

        if !suppressDelegateNotification {
            delegate?.floorplanScaleViewDidReset(self)
        }
    }

    func resignFirstResponder(_ suppressDelegateNotification: Bool = false) -> Bool {
        reset(suppressDelegateNotification)
        return super.resignFirstResponder()
    }

    func pointSelected(_ gestureRecognizer: UITapGestureRecognizer) {
        if let floorplanImageView = delegate?.floorplanImageViewForFloorplanScaleView(self) {
            let point = gestureRecognizer.location(in: floorplanImageView)

            if let _ = firstPoint {
                if secondPoint == nil {
                    secondPoint = point
                    instructionLabel.text = "Enter the measurement in feet to set scale"
                    updateLineEndpoints()

                    dispatch_after_delay(0.1) {
                        self.measurementTextField.becomeFirstResponder()
                        self.delegate?.floorplanScaleViewCanSetFloorplanScale(self)
                    }
                }
            } else {
                firstPoint = point
                instructionLabel.text = "Tap the location at which measuring ended"
                updateLineEndpoints()
            }
        }
    }

    fileprivate func updateLineEndpoints() {
        if let floorplanImageView = delegate?.floorplanImageViewForFloorplanScaleView(self) {
            let singlePoint = firstPoint != nil && secondPoint == nil
            let canDrawLine = firstPoint != nil && secondPoint != nil

            if singlePoint {
                firstPointView = FloorplanPolygonVertexView(image: (UIImage(named: "map-pin")?.scaledToWidth(75.0))!)
                firstPointView.delegate = self
                firstPointView.frame.origin = CGPoint(x: firstPoint.x - (firstPointView.image!.size.width / 2.0),
                                                      y: firstPoint.y - firstPointView.image!.size.height)

                floorplanImageView.addSubview(firstPointView)
                floorplanImageView.bringSubview(toFront: firstPointView)
            } else if canDrawLine {
                secondPointView = FloorplanPolygonVertexView(image: (UIImage(named: "map-pin")?.scaledToWidth(75.0))!)
                secondPointView.delegate = self
                secondPointView.frame.origin = CGPoint(x: secondPoint.x - (secondPointView.image!.size.width / 2.0),
                                                       y: secondPoint.y - secondPointView.image!.size.height)

                floorplanImageView.addSubview(secondPointView)
                floorplanImageView.bringSubview(toFront: secondPointView)

                removeGestureRecognizer()
                redrawLineSegment()
            }
        }
    }

    fileprivate func redrawLineSegment() {
        if let floorplanImageView = delegate?.floorplanImageViewForFloorplanScaleView(self) {
            let canDrawLine = firstPoint != nil && secondPoint != nil
            if canDrawLine {
                var attachLineView = false
                if lineView == nil {
                    lineView = FloorplanPolygonLineView()
                    attachLineView = true
                } else if lineView.superview == nil {
                    attachLineView = true
                }

                if attachLineView {
                    floorplanImageView.addSubview(lineView)
                    floorplanImageView.bringSubview(toFront: lineView)

                    floorplanImageView.bringSubview(toFront: firstPointView)
                    floorplanImageView.bringSubview(toFront: secondPointView)
                }
                
                lineView.setPoints(firstPoint, endPoint: secondPoint)
                populateMeasurementTextFieldFromCurrentScale()
            }
        }
    }

    // MARK: FloorplanPolygonVertexViewDelegate

    func floorplanPolygonVertexViewShouldReceiveTouch(_ view: FloorplanPolygonVertexView) -> Bool {
        return true
    }

    func floorplanPolygonVertexViewShouldRedrawVertices(_ view: FloorplanPolygonVertexView) { // FIXME -- poorly named method... maybe use Invalidated instead of ShouldRedraw...
        if view == firstPointView {
            firstPoint = CGPoint(x: view.frame.origin.x + (firstPointView.image!.size.width / 2.0),
                                 y: view.frame.origin.y + firstPointView.image!.size.height)
        } else if view == secondPointView {
            secondPoint = CGPoint(x: view.frame.origin.x + (secondPointView.image!.size.width / 2.0),
                                  y: view.frame.origin.y + secondPointView.image!.size.height)
        }

        if let lineView = lineView {
            if firstPoint != nil && secondPoint != nil {
                lineView.setPoints(firstPoint, endPoint: secondPoint)
                populateMeasurementTextFieldFromCurrentScale()
            }
        }
    }

    func floorplanPolygonVertexViewTapped(_ view: FloorplanPolygonVertexView) {
        // no-op
    }

    fileprivate func populateMeasurementTextFieldFromCurrentScale() {
        if let currentScale = delegate?.floorplanScaleForFloorplanScaleView(self) {
            if currentScale > 0.0 {
                let rawDistance = Float(distance / currentScale)
                measurementTextField.text = "\(ceilf(rawDistance * 100.0) / 100.0)"
            }
        }
    }

    // MARK: UITextFieldDelegate

    func textFieldDidBeginEditing(_ textField: UITextField) {

    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (string =~ "[.]") && textField.text!.range(of: ".") != nil {
            return false
        }
        self.saveButton?.isHidden = (string.length == 0 && textField.text!.length == 1) || textField.text!.length == 0
        return string.length == 0 || (string =~ "[0-9.]")
    }
}
