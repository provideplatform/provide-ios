//
//  PaymentViewController.swift
//  provide
//
//  Created by Kyle Thomas on 1/3/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class PaymentViewController: WorkOrderComponentViewController, CardIOViewDelegate {

    @IBOutlet private weak var signatureView: SignatureView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func render() {
        let frame = CGRectMake(0.0,
            targetView.frame.size.height,
            targetView.frame.size.width,
            view.frame.size.height)

        view.alpha = 0.0
        view.frame = frame

        //view.addDropShadow(CGSizeMake(1.0, 1.0), radius: 2.5, opacity: 1.0)

        targetView.addSubview(view)

        //setupNavigationItem()

        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: { () -> Void in
                self.view.alpha = 1
                self.view.frame = CGRectMake(frame.origin.x,
                    frame.origin.y - self.view.frame.size.height,
                    frame.size.width,
                    frame.size.height)

            },
            completion: { (complete) -> Void in

            }
        )
    }

    // MARK - CardIOViewDelegate

    func cardIOView(cardIOView: CardIOView, didScanCard cardInfo: CardIOCreditCardInfo) {
        print("did scan card")
    }
    
}
