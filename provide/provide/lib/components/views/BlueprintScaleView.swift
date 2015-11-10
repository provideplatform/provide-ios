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
    func blueprintScaleViewDidReset(view: BlueprintScaleView)
}

class BlueprintScaleView: UIView, BlueprintPolygonVertexViewDelegate, UITextFieldDelegate {

    var delegate: BlueprintScaleViewDelegate! {
        didSet {
            if let _ = delegate {
                measurementTextField.text = ""
            }
        }
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

    private func reset() {
        firstPoint = nil
        secondPoint = nil

        removeGestureRecognizer()

        if let firstPointView = firstPointView {
            firstPointView.removeFromSuperview()
        }

        if let secondPointView = secondPointView {
            secondPointView.removeFromSuperview()
        }

        if let lineView = lineView {
            lineView.removeFromSuperview()
        }

        delegate?.blueprintScaleViewDidReset(self)
    }

    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
    }

    func pointSelected(gestureRecognizer: UITapGestureRecognizer) {
        if let blueprintImageView = delegate?.blueprintImageViewForBlueprintScaleView(self) {
            let point = gestureRecognizer.locationInView(blueprintImageView)

            if let _ = firstPoint {
                if secondPoint == nil {
                    secondPoint = point
                    updateLineEndpoints()
                }
            } else {
                firstPoint = point
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
                if lineView == nil {
                    lineView = BlueprintPolygonLineView()
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

    func blueprintPolygonVertexViewShouldRedrawVertices(view: BlueprintPolygonVertexView) {
        if view == firstPointView {
            firstPoint = CGPoint(x: view.frame.origin.x + (firstPointView.image!.size.width / 2.0),
                                 y: view.frame.origin.y + (firstPointView.image!.size.width / 2.0))
        } else if view == secondPointView {
            secondPoint = CGPoint(x: view.frame.origin.x + (secondPointView.image!.size.width / 2.0),
                                  y: view.frame.origin.y + (secondPointView.image!.size.width / 2.0))
        }

        if let lineView = lineView {
            lineView.setPoints(firstPoint, endPoint: secondPoint)
        }
    }

    // MARK: UITextFieldDelegate

    func textFieldDidBeginEditing(textField: UITextField) {

    }

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        print("measurement replacement string: \(string) for character range: \(range)")
        return true
    }
}
