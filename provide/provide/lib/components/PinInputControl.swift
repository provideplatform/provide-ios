//
//  PinInputControl.swift
//  provide
//
//  Created by Kyle Thomas on 11/26/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol PinInputControlDelegate {
    func pinInputControl(pinInputControl : PinInputControl, didCompleteEnteringPin: String)
}

// @IBDesignable // Comment out for now due to weird storyboard error
class PinInputControl : UIControl, UIKeyInput, UIInputViewAudioFeedback, UITextInputTraits {

    let maxPinLength = 4

    let boxWidth: CGFloat = 40
    let boxHeight: CGFloat = 50

    let cornerRadius: CGFloat = 4
    let borderWidth: CGFloat = 1
    let dotRadius: CGFloat = 4
    let inBetweenSpacing: CGFloat = 8

    let fadeStartDelay = 0.1

    var delegate: PinInputControlDelegate? // Public

    private var pin: String = ""

    // UITextInputTraits protocol
    var keyboardType: UIKeyboardType = .NumberPad

    // UIInputViewAudioFeedback protocol
    var enableInputClicksWhenVisible: Bool {
        return true
    }

    override func drawRect(rect: CGRect) {
        let boxesBoundingWidth = inBetweenSpacing * 3.0 + boxWidth * 4.0
        var startX = (bounds.width - boxesBoundingWidth) / 2.0
        let startY = (bounds.height - boxHeight) / 2.0

        let context = UIGraphicsGetCurrentContext()

        for i in 0..<maxPinLength {
            // Set stroke and fill
            Color.pinInputControlBoxBorderColor().setStroke()
            UIColor.whiteColor().setFill()

            // StrokePath
            let strokePath = UIBezierPath(roundedRect: CGRectMake(startX + borderWidth, startY + borderWidth, boxWidth - (borderWidth * 2), boxHeight - (borderWidth * 2)), cornerRadius: cornerRadius)
            strokePath.lineWidth = borderWidth * 2
            strokePath.stroke()

            // FillPath
            let fillPath = UIBezierPath(roundedRect: CGRectMake(startX + borderWidth, startY + borderWidth, boxWidth - (borderWidth * 2), boxHeight - (borderWidth * 2)), cornerRadius: cornerRadius)
            fillPath.fill()

            if i < pin.length {
                UIColor.blackColor().setFill()
                CGContextFillEllipseInRect(context, CGRectMake(startX + boxWidth/2 - dotRadius, startY + boxHeight/2 - dotRadius, dotRadius * 2, dotRadius * 2))
            }

            startX += (boxWidth + inBetweenSpacing)
        }
    }

    // UIKeyInput
    func insertText(newChar: String) {
        if newChar.isDigit() && pin.length < maxPinLength {
            pin += newChar
            textChanged()

            if pin.length == maxPinLength {
                delegate?.pinInputControl(self, didCompleteEnteringPin: pin)
            }
        }
    }

    func resetView() {
        dispatch_after_delay(fadeStartDelay) {
            self.pin = ""
            self.textChanged()
            UIView.transitionWithView(self) {
                self.layer.displayIfNeeded()
            }
        }
    }

    func deleteBackward()  {
        if !pin.isEmpty {
            pin = pin.substringToIndex(pin.endIndex.predecessor())
            textChanged()
        }
    }

    func hasText() -> Bool  {
        return pin.isEmpty
    }

    private func textChanged() {
        setNeedsDisplay()
        UIDevice.currentDevice().playInputClick()
        sendActionsForControlEvents(.EditingChanged)
    }

    // UIResponder
    override func canBecomeFirstResponder() -> Bool {
        return true
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)

        if !isFirstResponder() {
            becomeFirstResponder()
        }
    }
}
