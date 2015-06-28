//
//  SignaturePanelView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

@objc
protocol SignatureViewDelegate {
    func signatureView(signatureView: SignatureView, capturedSignature signature: UIImage)
}

class SignatureView: UIView {

    var delegate: SignatureViewDelegate!

    @IBOutlet private weak var doneButton: UIButton!

    private let minTouchesRequired = 20
    private var path: UIBezierPath!
    private var writing = false
    private var touches = 0

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        multipleTouchEnabled = false
        backgroundColor = UIColor.whiteColor()

        path = UIBezierPath()
        path.lineWidth = 4.0
    }

    override func drawRect(rect: CGRect) {
        UIColor.blackColor().setStroke()
        path.stroke()
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        writing = true

        if let touch = touches.first {
            let pt = touch.locationInView(touch.view)
            path.moveToPoint(pt)
        }

        write(touches)
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        write(touches)
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        write(touches)
        writing = false
    }

    private func write(touches: Set<UITouch>) {
        for touch in touches {
            let pt = touch.locationInView(touch.view)
            path.addLineToPoint(pt)

            self.touches++

            setNeedsDisplay()
        }

        if self.touches >= minTouchesRequired {
            enableDoneButton()
        }
    }

    private func enableDoneButton() {
        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseInOut,
            animations: {
                self.doneButton.alpha = 1
            },
            completion: { finished in
                self.doneButton.enabled = true
            }
        )
    }

    @IBAction func doneButtonPressed(sender: UIButton) {
        doneButton.enabled = false
        doneButton.alpha = 0
        doneButton.removeTarget(nil, action: nil, forControlEvents: .AllEvents)

        if let delegate = delegate {
            delegate.signatureView(self, capturedSignature: image())
        }
    }

    func image() -> UIImage {
        let imageSize = bounds.size

        UIGraphicsBeginImageContext(imageSize)
        let imageContext = UIGraphicsGetCurrentContext()

        //CGContextTranslateCTM(imageContext, 0.0, imageSize.height)
        //CGContextScaleCTM(imageContext, 1.0, -1.0)

        layer.renderInContext(imageContext)
        let img = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return img
    }
}
