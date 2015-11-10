//
//  BlueprintScaleView.swift
//  provide
//
//  Created by Kyle Thomas on 11/10/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol BlueprintScaleViewDelegate {
    func blueprintImageViewForBlueprintScaleView(view: BlueprintScaleView) -> UIImageView!
    func blueprintScaleViewCanSetBlueprintScale(view: BlueprintScaleView)
    func blueprintScaleViewDidReset(view: BlueprintScaleView)
}

class BlueprintScaleView: UIView, BlueprintPolygonVertexViewDelegate, UITextFieldDelegate {

    var delegate: BlueprintScaleViewDelegate! {
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
            let measuredDistance = CGFloat(Float(measurementText)!)
            return distance / measuredDistance
        }
        return 0.0
    }

    @IBOutlet private weak var instructionLabel: UILabel!
    @IBOutlet private weak var measurementTextField: UITextField!

    private var firstPoint: CGPoint!
    private var secondPoint: CGPoint!

    private var firstPointView: BlueprintPolygonVertexView!
    private var secondPointView: BlueprintPolygonVertexView!

    private var lineView: BlueprintPolygonLineView!

    private var targetView: UIView! {
        if let superview = self.superview {
            return superview
        }
        return nil
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
            delegate?.blueprintScaleViewDidReset(self)
        }
    }

    func resignFirstResponder(suppressDelegateNotification: Bool = false) -> Bool {
        reset(suppressDelegateNotification)
        return super.resignFirstResponder()
    }

    func pointSelected(gestureRecognizer: UITapGestureRecognizer) {
        if let blueprintImageView = delegate?.blueprintImageViewForBlueprintScaleView(self) {
            let point = gestureRecognizer.locationInView(blueprintImageView)

            if let _ = firstPoint {
                if secondPoint == nil {
                    secondPoint = point
                    instructionLabel.text = "Enter the measurement in feet to set scale"
                    updateLineEndpoints()

                    dispatch_after_delay(0.1) {
                        self.measurementTextField.becomeFirstResponder()
                        self.delegate?.blueprintScaleViewCanSetBlueprintScale(self)
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
        if let blueprintImageView = delegate?.blueprintImageViewForBlueprintScaleView(self) {
            let singlePoint = firstPoint != nil && secondPoint == nil
            let canDrawLine = firstPoint != nil && secondPoint != nil

            if singlePoint {
                firstPointView = BlueprintPolygonVertexView(image: (UIImage(named: "map-pin")?.scaledToWidth(50.0))!)
                firstPointView.delegate = self
                firstPointView.frame.origin = CGPoint(x: firstPoint.x - (firstPointView.image!.size.width / 2.0),
                                                      y: firstPoint.y - (firstPointView.image!.size.height / 2.0))

                blueprintImageView.addSubview(firstPointView)
                blueprintImageView.bringSubviewToFront(firstPointView)
            } else if canDrawLine {
                secondPointView = BlueprintPolygonVertexView(image: (UIImage(named: "map-pin")?.scaledToWidth(50.0))!)
                secondPointView.delegate = self
                secondPointView.frame.origin = CGPoint(x: secondPoint.x - (secondPointView.image!.size.width / 2.0),
                                                       y: secondPoint.y - (secondPointView.image!.size.height / 2.0))

                blueprintImageView.addSubview(secondPointView)
                blueprintImageView.bringSubviewToFront(secondPointView)

                removeGestureRecognizer()
                redrawLineSegment()
            }
        }
    }

    private func redrawLineSegment() {
        if let blueprintImageView = delegate?.blueprintImageViewForBlueprintScaleView(self) {
            let canDrawLine = firstPoint != nil && secondPoint != nil
            if canDrawLine {
                var attachLineView = false
                if lineView == nil {
                    lineView = BlueprintPolygonLineView()
                    attachLineView = true
                } else if lineView.superview == nil {
                    attachLineView = true
                }

                if attachLineView {
                    blueprintImageView.addSubview(lineView)
                    blueprintImageView.bringSubviewToFront(lineView)

                    blueprintImageView.bringSubviewToFront(firstPointView)
                    blueprintImageView.bringSubviewToFront(secondPointView)
                }
                
                lineView.setPoints(firstPoint, endPoint: secondPoint)
            }
        }
    }

    // MARK: BlueprintPolygonVertexViewDelegate

    func blueprintPolygonVertexViewShouldRedrawVertices(view: BlueprintPolygonVertexView) { // FIXME -- poorly named method... maybe use Invalidated instead of ShouldRedraw...
        if view == firstPointView {
            firstPoint = CGPoint(x: view.frame.origin.x + (firstPointView.image!.size.width / 2.0),
                                 y: view.frame.origin.y + (firstPointView.image!.size.width / 2.0))
        } else if view == secondPointView {
            secondPoint = CGPoint(x: view.frame.origin.x + (secondPointView.image!.size.width / 2.0),
                                  y: view.frame.origin.y + (secondPointView.image!.size.width / 2.0))
        }

        if let lineView = lineView {
            if firstPoint != nil && secondPoint != nil {
                lineView.setPoints(firstPoint, endPoint: secondPoint)
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
        return string.length == 0 || (string =~ "[0-9.]")
    }
}
