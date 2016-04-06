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

    private var backgroundSubview: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clearColor()
        view.tintColor = UIColor.whiteColor()

        view.alpha = 0.0
        view.frame.origin.y = view.frame.height

        backgroundSubview = UIView(frame: view.bounds)
        let size = max(backgroundSubview.frame.size.width, backgroundSubview.frame.size.height)
        backgroundSubview.frame.size = CGSize(width: size, height: size)
        backgroundSubview.alpha = 0.78
        backgroundSubview.backgroundColor = UIColor.blackColor()
        view.addSubview(backgroundSubview)
        view.sendSubviewToBack(backgroundSubview)

        view.bringSubviewToFront(imageView)
        //view.bringSubviewToFront(label)
        view.bringSubviewToFront(messageLabel)
    }

    func setLabelText(labelText: String) {
        label.text = labelText
    }

    func setMessage(message: String) {
        messageLabel.text = message
    }

    func render(targetView: UIView) {
        render(targetView, animated: true)
    }

    func render(targetView: UIView, animated: Bool) {
        if let superview = view.superview {
            if targetView == superview {
                return
            }
        }

        targetView.addSubview(view)
        targetView.bringSubviewToFront(view)

        if animated {
            UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseOut,
                animations: {
                    self.view.alpha = 1.0
                    self.view.frame.origin.y -= self.view.frame.height
                },
                completion: { completed in
                    
                }
            )
        } else {
            view.alpha = 1.0
            view.frame.origin.y -= view.frame.height
        }

    }

    func dismiss() {
        if let _ = view.superview {
            UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseIn,
                animations: {
                    self.view.alpha = 0.0
                    self.view.frame.origin.y += self.view.frame.height
                },
                completion: { completed in
                    self.view.removeFromSuperview()
                }
            )
        }
    }
}
