//
//  NetPromoterViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class NetPromoterViewController: WorkOrderComponentViewController {

    @IBOutlet private weak var promptTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
        view.transform = transform

        view.backgroundColor = UIColor.clearColor()
        view.alpha = 1

        view.subviews[1].roundCorners(3.0)
    }

    override func render() {
        let frame = CGRect(
            x: 0.0,
            y: targetView.frame.height,
            width: targetView.frame.width,
            height: targetView.frame.height)

        view.alpha = 0.0
        view.frame = frame

        targetView.addSubview(view)

        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: {
                self.view.alpha = 1
                self.view.frame = CGRect(
                    x: 0.0,
                    y: 0.0,
                    width: frame.width,
                    height: frame.height
                )
            },
            completion: { complete in

            }
        )
    }

    override func unwind() {
        clearNavigationItem()

        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: {
                self.view.alpha = 0
                self.view.frame = CGRect(
                    x: self.view.frame.origin.x,
                    y: -self.view.frame.height,
                    width: self.view.frame.width,
                    height: self.view.frame.height
                )
            },
            completion: { complete in

            }
        )
    }

    @IBAction func cancel(sender: UIButton) {
        workOrdersViewControllerDelegate?.netPromoterScoreDeclinedForWorkOrderViewController?(self)
    }

    @IBAction func rate(sender: UIButton) {
        workOrdersViewControllerDelegate?.netPromoterScoreReceived?(sender.tag / 1000, forWorkOrderViewController: self)
    }
}
