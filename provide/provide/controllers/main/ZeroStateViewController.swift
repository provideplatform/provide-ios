//
//  ZeroStateViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/1/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class ZeroStateViewController: ViewController {

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!

    private var backgroundSubview: UIView! {
        let backgroundSubview = UIView(frame: view.bounds)
        backgroundSubview.alpha = 0.65
        backgroundSubview.backgroundColor = UIColor.blackColor()
        return backgroundSubview
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clearColor()
        view.tintColor = UIColor.whiteColor()

        view.alpha = 0.0
        view.frame.origin.y = view.frame.height

        view.addSubview(backgroundSubview)
        view.sendSubviewToBack(backgroundSubview)

        //imageView.image = FAKFontAwesome.checkCircleOIconWithSize(imageView.bounds.width).imageWithSize(imageView.bounds.size)

        view.bringSubviewToFront(imageView)
        view.bringSubviewToFront(label)
        view.bringSubviewToFront(messageLabel)
    }

    func render(targetView: UIView) {
        if let superview = view.superview {
            if targetView == superview {
                return
            }
        }

        targetView.addSubview(view)
        targetView.bringSubviewToFront(view)

        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseOut, animations: { () -> Void in
            self.view.alpha = 1.0
            self.view.frame.origin.y -= self.view.frame.height
        },
        completion: { (completed) -> Void in

        })
    }

    func dismiss() {
        if let _ = view.superview {
            UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseIn, animations: { () -> Void in
                self.view.alpha = 0.0
                self.view.frame.origin.y += self.view.frame.height
            },
            completion: { (completed) -> Void in
                self.view.removeFromSuperview()
            })
        }
    }
}
