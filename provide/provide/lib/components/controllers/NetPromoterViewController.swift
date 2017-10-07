//
//  NetPromoterViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

class NetPromoterViewController: WorkOrderComponentViewController {

    @IBOutlet private weak var promptTextView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
        view.transform = transform

        view.backgroundColor = .clear
        view.alpha = 1

        view.subviews[1].roundCorners(3.0)
    }

    override func render() {
        let frame = CGRect(
            x: 0.0,
            y: targetView.height,
            width: targetView.width,
            height: targetView.height)

        view.alpha = 0.0
        view.frame = frame

        targetView.addSubview(view)

        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
            self.view.alpha = 1
            self.view.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        })
    }

    override func unwind() {
        clearNavigationItem()

        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
            self.view.alpha = 0
            self.view.frame = CGRect(
                x: self.view.frame.origin.x,
                y: -self.view.height,
                width: self.view.width,
                height: self.view.height
            )
        })
    }

    @IBAction func cancel(_ sender: UIButton) {
        workOrdersViewControllerDelegate?.netPromoterScoreDeclinedForWorkOrderViewController?(self)
    }

    @IBAction func rate(_ sender: UIButton) {
        let tag = NSNumber(value: Double(sender.tag) / 1000.0)
        workOrdersViewControllerDelegate?.netPromoterScoreReceived?(tag, forWorkOrderViewController: self)
    }
}
