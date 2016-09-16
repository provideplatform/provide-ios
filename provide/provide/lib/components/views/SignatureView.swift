//
//  SignaturePanelView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

@objc
protocol SignatureViewDelegate {
    func signatureView(_ signatureView: SignatureView, capturedSignature signature: UIImage)
}

class SignatureView: UIView {

    var delegate: SignatureViewDelegate!

    @IBOutlet fileprivate weak var clearButton: UIButton!
    @IBOutlet fileprivate weak var doneButton: UIButton!

    fileprivate let minTouchesRequired = 20
    fileprivate var path: UIBezierPath!
    fileprivate var writing = false
    fileprivate var touches = 0 {
        didSet {
            if touches == 0 {
                hideClearButton()
                hideDoneButton()
            } else {
                enableClearButton()

                if touches >= minTouchesRequired {
                    enableDoneButton()
                }
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        isMultipleTouchEnabled = false
        backgroundColor = UIColor.white

        path = UIBezierPath()
        path.lineWidth = 3.0
    }

    override func draw(_ rect: CGRect) {
        UIColor.black.setStroke()
        path.stroke()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        writing = true

        if let touch = touches.first {
            let pt = touch.location(in: touch.view)
            path.move(to: pt)
        }

        write(touches)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        write(touches)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        write(touches)
        writing = false
    }

    fileprivate func write(_ touches: Set<UITouch>) {
        for touch in touches {
            let pt = touch.location(in: touch.view)
            path.addLine(to: pt)

            self.touches += 1

            setNeedsDisplay()
        }
    }

    fileprivate func enableClearButton() {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions(),
            animations: {
                self.clearButton.alpha = 1.0
            },
            completion: { finished in
                self.clearButton.isEnabled = true
                self.clearButton.addTarget(self, action: #selector(SignatureView.clear), for: .touchUpInside)
            }
        )
    }

    fileprivate func hideClearButton() {
        clearButton.removeTarget(nil, action: nil, for: .allEvents)

        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions(),
            animations: {
                self.clearButton.alpha = 0.0
            },
            completion: { finished in
                self.clearButton.isEnabled = false
            }
        )
    }

    fileprivate func enableDoneButton() {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions(),
            animations: {
                self.doneButton.alpha = 1.0
            },
            completion: { finished in
                self.doneButton.isEnabled = true
                self.doneButton.addTarget(self, action: #selector(SignatureView.done), for: .touchUpInside)
            }
        )
    }

    fileprivate func hideDoneButton() {
        doneButton.removeTarget(nil, action: nil, for: .allEvents)

        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIViewAnimationOptions(),
            animations: {
                self.doneButton.alpha = 0.0
            },
            completion: { finished in
                self.doneButton.isEnabled = false
            }
        )
    }

    func clear() {
        hideClearButton()
        hideDoneButton()

        touches = 0

        path.removeAllPoints()
        setNeedsDisplay()
    }

    func done() {
        hideClearButton()
        hideDoneButton()

        if let delegate = delegate {
            delegate.signatureView(self, capturedSignature: image())
        }
    }

    func image() -> UIImage {
        let imageSize = bounds.size

        UIGraphicsBeginImageContext(imageSize)
        let imageContext = UIGraphicsGetCurrentContext()!

        layer.render(in: imageContext)
        let img = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return img!
    }
}
