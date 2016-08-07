//
//  FloorplanScaleView.swift
//  provide
//
//  Created by Kyle Thomas on 11/10/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

protocol FloorplanScaleViewDelegate {
    func floorplanImageViewForFloorplanScaleView(view: FloorplanScaleView) -> UIImageView!
    func floorplanScaleForFloorplanScaleView(view: FloorplanScaleView) -> CGFloat
    func floorplanScaleViewCanSetFloorplanScale(view: FloorplanScaleView)
    func floorplanScaleView(view: FloorplanScaleView, didSetScale scale: CGFloat)
    func floorplanScaleViewDidReset(view: FloorplanScaleView)
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

    @IBOutlet private weak var instructionLabel: UILabel!
    @IBOutlet private weak var measurementTextField: UITextField!
    @IBOutlet private weak var saveButton: UIButton! {
        didSet {
            if let saveButton = saveButton {
                saveButton.hidden = true
                saveButton.addTarget(self, action: #selector(FloorplanScaleView.setScale), forControlEvents: .TouchUpInside)
            }
        }
    }

    private var firstPoint: CGPoint!
    private var secondPoint: CGPoint!

    private var firstPointView: FloorplanPolygonVertexView!
    private var secondPointView: FloorplanPolygonVertexView!

    private var lineView: FloorplanPolygonLineView!

    private var targetView: UIView! {
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

    private func removeGestureRecognizer() {
        if let targetView = targetView {
            targetView.removeGestureRecognizers()
        }
    }

    private func reset(suppressDelegateNotification: Bool = false) {
        firstPoint = nil
        secondPoint = nil

        removeGestureRecognizer()

        if let measurementTextField = measurementTextField {
            if measurementTextField.isFirstResponder() {
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

    func resignFirstResponder(suppressDelegateNotification: Bool = false) -> Bool {
        reset(suppressDelegateNotification)
        return super.resignFirstResponder()
    }

    func pointSelected(gestureRecognizer: UITapGestureRecognizer) {
        if let floorplanImageView = delegate?.floorplanImageViewForFloorplanScaleView(self) {
            let point = gestureRecognizer.locationInView(floorplanImageView)

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

    private func updateLineEndpoints() {
        if let floorplanImageView = delegate?.floorplanImageViewForFloorplanScaleView(self) {
            let singlePoint = firstPoint != nil && secondPoint == nil
            let canDrawLine = firstPoint != nil && secondPoint != nil

            if singlePoint {
                firstPointView = FloorplanPolygonVertexView(image: (UIImage(named: "map-pin")?.scaledToWidth(75.0))!)
                firstPointView.delegate = self
                firstPointView.frame.origin = CGPoint(x: firstPoint.x - (firstPointView.image!.size.width / 2.0),
                                                      y: firstPoint.y - firstPointView.image!.size.height)

                floorplanImageView.addSubview(firstPointView)
                floorplanImageView.bringSubviewToFront(firstPointView)
            } else if canDrawLine {
                secondPointView = FloorplanPolygonVertexView(image: (UIImage(named: "map-pin")?.scaledToWidth(75.0))!)
                secondPointView.delegate = self
                secondPointView.frame.origin = CGPoint(x: secondPoint.x - (secondPointView.image!.size.width / 2.0),
                                                       y: secondPoint.y - secondPointView.image!.size.height)

                floorplanImageView.addSubview(secondPointView)
                floorplanImageView.bringSubviewToFront(secondPointView)

                removeGestureRecognizer()
                redrawLineSegment()
            }
        }
    }

    private func redrawLineSegment() {
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
                    floorplanImageView.bringSubviewToFront(lineView)

                    floorplanImageView.bringSubviewToFront(firstPointView)
                    floorplanImageView.bringSubviewToFront(secondPointView)
                }
                
                lineView.setPoints(firstPoint, endPoint: secondPoint)
                populateMeasurementTextFieldFromCurrentScale()
            }
        }
    }

    // MARK: FloorplanPolygonVertexViewDelegate

    func floorplanPolygonVertexViewShouldReceiveTouch(view: FloorplanPolygonVertexView) -> Bool {
        return true
    }

    func floorplanPolygonVertexViewShouldRedrawVertices(view: FloorplanPolygonVertexView) { // FIXME -- poorly named method... maybe use Invalidated instead of ShouldRedraw...
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

    func floorplanPolygonVertexViewTapped(view: FloorplanPolygonVertexView) {
        // no-op
    }

    private func populateMeasurementTextFieldFromCurrentScale() {
        if let currentScale = delegate?.floorplanScaleForFloorplanScaleView(self) {
            if currentScale > 0.0 {
                let rawDistance = Float(distance / currentScale)
                measurementTextField.text = "\(ceilf(rawDistance * 100.0) / 100.0)"
            }
        }
    }

    // MARK: UITextFieldDelegate

    func textFieldDidBeginEditing(textField: UITextField) {

    }

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if (string =~ "[.]") && textField.text!.contains(".") {
            return false
        }
        self.saveButton?.hidden = (string.length == 0 && textField.text!.length == 1) || textField.text!.length == 0
        return string.length == 0 || (string =~ "[0-9.]")
    }
}
