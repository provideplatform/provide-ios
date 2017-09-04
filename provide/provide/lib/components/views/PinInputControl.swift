//
//  PinInputControl.swift
//  provide
//
//  Created by Kyle Thomas on 11/26/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

protocol PinInputControlDelegate {
    func pinInputControl(_ pinInputControl : PinInputControl, didCompleteEnteringPin: String)
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

    fileprivate var pin: String = ""

    // UITextInputTraits protocol
    var keyboardType: UIKeyboardType = .numberPad

    // UIInputViewAudioFeedback protocol
    var enableInputClicksWhenVisible: Bool {
        return true
    }

    override func draw(_ rect: CGRect) {
        let boxesBoundingWidth = inBetweenSpacing * 3.0 + boxWidth * 4.0
        var startX = (bounds.width - boxesBoundingWidth) / 2.0
        let startY = (bounds.height - boxHeight) / 2.0

        let context = UIGraphicsGetCurrentContext()

        for i in 0..<maxPinLength {
            // Set stroke and fill
            Color.pinInputControlBoxBorderColor().setStroke()
            UIColor.white.setFill()

            // StrokePath
            let strokePath = UIBezierPath(roundedRect: CGRect(x: startX + borderWidth, y: startY + borderWidth, width: boxWidth - (borderWidth * 2), height: boxHeight - (borderWidth * 2)), cornerRadius: cornerRadius)
            strokePath.lineWidth = borderWidth * 2
            strokePath.stroke()

            // FillPath
            let fillPath = UIBezierPath(roundedRect: CGRect(x: startX + borderWidth, y: startY + borderWidth, width: boxWidth - (borderWidth * 2), height: boxHeight - (borderWidth * 2)), cornerRadius: cornerRadius)
            fillPath.fill()

            if i < pin.length {
                UIColor.black.setFill()
                context?.fillEllipse(in: CGRect(x: startX + boxWidth/2 - dotRadius, y: startY + boxHeight/2 - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
            }

            startX += (boxWidth + inBetweenSpacing)
        }
    }

    // UIKeyInput
    func insertText(_ newChar: String) {
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
            pin = pin.substring(to: pin.characters.index(before: pin.endIndex))
            textChanged()
        }
    }

    var hasText : Bool  {
        return pin.isEmpty
    }

    fileprivate func textChanged() {
        setNeedsDisplay()
        UIDevice.current.playInputClick()
        sendActions(for: .editingChanged)
    }

    // UIResponder
    override var canBecomeFirstResponder : Bool {
        return true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        if !isFirstResponder {
            becomeFirstResponder()
        }
    }
}
