//
//  ZeroStateViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/1/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class ZeroStateViewController: ViewController {

    @IBOutlet fileprivate weak var imageView: UIImageView!
    @IBOutlet fileprivate weak var label: UILabel!
    @IBOutlet fileprivate weak var messageLabel: UILabel!

    fileprivate var backgroundSubview: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        view.tintColor = .white

        view.alpha = 0.0
        view.frame.origin.y = view.height

        backgroundSubview = UIView(frame: view.bounds)
        let size = max(backgroundSubview.width, backgroundSubview.frame.height)
        backgroundSubview.frame.size = CGSize(width: size, height: size)
        backgroundSubview.alpha = 0.78
        backgroundSubview.backgroundColor = .black
        view.addSubview(backgroundSubview)
        view.sendSubview(toBack: backgroundSubview)

        for item in [imageView, label, messageLabel] as [Any] {
            if let v = item as? UIView {
                view.bringSubview(toFront: v)
            }
        }
    }

    func setLabelText(_ labelText: String) {
        label.text = labelText
    }

    func setMessage(_ message: String) {
        messageLabel.text = message
    }

    func render(_ targetView: UIView) {
        render(targetView, animated: true)
    }

    func render(_ targetView: UIView, animated: Bool) {
        if let superview = view.superview {
            if targetView == superview {
                return
            }
        }

        targetView.addSubview(view)
        targetView.bringSubview(toFront: view)

        if animated {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
                self.view.alpha = 1.0
                self.view.frame.origin.y -= self.view.height
            })
        } else {
            view.alpha = 1.0
            view.frame.origin.y -= view.height
        }
    }

    func dismiss() {
        if view.superview != nil {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
                self.view.alpha = 0.0
                self.view.frame.origin.y += self.view.height
            }, completion: { completed in
                self.view.removeFromSuperview()
            })
        }
    }
}
