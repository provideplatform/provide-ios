//
//  SignatureViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class SignatureViewController: WorkOrderComponentViewController, SignatureViewDelegate {

    @IBOutlet private weak var signatureView: SignatureView!
    @IBOutlet private weak var summaryLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        let transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
        view.transform = transform

        view.backgroundColor = UIColor.clearColor()
        view.alpha = 1

        (view.subviews[1] as! UIView).roundCorners(3.0)

        signatureView.delegate = self
    }

    override func render() {
        let frame = CGRectMake(0.0,
            targetView.frame.size.height,
            targetView.frame.size.width,
            targetView.frame.size.height)

        view.alpha = 0.0
        view.frame = frame

        targetView.addSubview(view)

        summaryLabel.text = workOrdersViewControllerDelegate?.summaryLabelTextForSignatureViewController?(self)

        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: {
                self.view.alpha = 1
                self.view.frame = CGRectMake(0.0,
                                             0.0,
                                             frame.size.width,
                                             frame.size.height)
            },
            completion: { complete in
                self.suspendTopViewGestureRecognizers()
            }
        )
    }

    override func unwind() {
        clearNavigationItem()

        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: {
                self.view.alpha = 0
                self.view.frame = CGRectMake(self.view.frame.origin.x,
                    -self.view.frame.size.height,
                    self.view.frame.size.width,
                    self.view.frame.size.height)
            },
            completion: { complete in
                self.enableSuspendedTopViewGestureRecognizers()
            }
        )
    }

    // MARK: SignatureViewDelegate

    func signatureView(signatureView: SignatureView!, capturedSignature signature: UIImage!) {
        workOrdersViewControllerDelegate?.signatureReceived?(signature, forWorkOrderViewController: self)
    }

}
