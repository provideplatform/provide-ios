//
//  ZeroStateViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/1/15.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import UIKit


class ZeroStateViewController: ViewController {

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!

    private let zeroStateImage: UIImage? = infoDictionaryValueFor("xAppZeroStateImage") != "" ? UIImage(named: infoDictionaryValueFor("xAppZeroStateImage")) : nil

    private var backgroundSubview: UIView!

    private var message: String!
    private var rendered = false

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

        if let image = zeroStateImage {
            imageView.image = image
        }

        for item in [imageView, label, messageLabel] as [Any] {
            if let v = item as? UIView {
                view.bringSubview(toFront: v)
            }
        }

        if let message = message {
            messageLabel.text = message
        }
    }

    func setMessage(_ message: String) {
        self.message = message
        messageLabel?.text = message
    }

    func render(_ targetView: UIView) {
        render(targetView, animated: true)
    }

    private func render(_ targetView: UIView, animated: Bool) {
        if rendered {
            return
        }

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
                self.rendered = true
            })
        } else {
            view.alpha = 1.0
            view.frame.origin.y -= view.height
            self.rendered = true
        }
    }

    func dismiss() {
        if view.superview != nil {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
                self.view.alpha = 0.0
                self.view.frame.origin.y += self.view.height
            }, completion: { completed in
                self.view.removeFromSuperview()
                self.rendered = false
            })
        }
    }
}
