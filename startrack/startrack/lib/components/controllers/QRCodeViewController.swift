//
//  QRCodeViewController.swift
//  startrack
//
//  Created by Kyle Thomas on 9/22/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol QRCodeViewControllerDelegate {
    func barcodeDataForQRCodeViewController(viewController: QRCodeViewController) -> String
    func promptForQRCodeViewController(viewController: QRCodeViewController) -> String!
    func titleForQRCodeViewController(viewController: QRCodeViewController) -> String!
}

class QRCodeViewController: WorkOrderComponentViewController {

    var qrCodeViewControllerDelegate: QRCodeViewControllerDelegate! {
        didSet {
            if let delegate = qrCodeViewControllerDelegate {
                let data = delegate.barcodeDataForQRCodeViewController(self)
                let rect = CGRect(x: 0.0, y: 0.0, width: view.frame.width, height: view.frame.width)
                qrCodeImage = UIImage.qrCodeImageWithString(data).resize(rect)
            } else {
                qrCodeImage = nil
            }
        }
    }

    private var qrCodeImageView: UIImageView! {
        didSet {
            if let _ = qrCodeImageView {
                refreshQRCodeImageView()
            }
        }
    }

    private var qrCodeImage: UIImage! {
        didSet {
            refreshQRCodeImageView()
        }
    }

    private func refreshQRCodeImageView() {
        if let qrCodeImage = qrCodeImage {
            qrCodeImageView?.image = qrCodeImage

            let length = qrCodeImage.size.width
            let delta = (length / 2.0) - (length / 2.0)
            qrCodeImageView?.frame = CGRect(x: delta, y: delta, width: length, height: length)
        } else {
            qrCodeImageView?.image = nil
        }
    }

//    private var dismissItem: UIBarButtonItem! {
//        let title = "DISMISS"
//        let dismissItem = UIBarButtonItem(title: title, style: .Plain, target: self, action: "dismiss")
//        dismissItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
//        return dismissItem
//    }

    private var hiddenNavigationControllerFrame: CGRect {
        return CGRect(
            x: 0.0,
            y: targetView.frame.height,
            width: targetView.frame.width,
            height: targetView.frame.height / 1.333
        )
    }

    private var renderedNavigationControllerFrame: CGRect {
        return CGRect(
            x: 0.0,
            y: hiddenNavigationControllerFrame.origin.y - hiddenNavigationControllerFrame.height,
            width: hiddenNavigationControllerFrame.width,
            height: hiddenNavigationControllerFrame.height
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationItem()

        qrCodeImageView = UIImageView()
        view.addSubview(qrCodeImageView)
    }

    func setupNavigationItem() {
        navigationItem.prompt = qrCodeViewControllerDelegate?.promptForQRCodeViewController(self)
        navigationItem.title = qrCodeViewControllerDelegate?.titleForQRCodeViewController(self)
        navigationItem.hidesBackButton = true

        navigationItem.leftBarButtonItems = []
        navigationItem.rightBarButtonItems = []
    }

    override func render() {
        let frame = hiddenNavigationControllerFrame

        view.alpha = 0.0
        view.frame = frame

        if let navigationController = navigationController {
            navigationController.view.alpha = 0.0
            navigationController.view.frame = hiddenNavigationControllerFrame
            targetView.addSubview(navigationController.view)
            targetView.bringSubviewToFront(navigationController.view)

            UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
                animations: {
                    self.view.alpha = 1
                    navigationController.view.alpha = 1
                    navigationController.view.frame = CGRect(
                        x: frame.origin.x,
                        y: frame.origin.y - navigationController.view.frame.height,
                        width: frame.width,
                        height: frame.height
                    )
                },
                completion: nil
            )
        }
    }

    override func unwind() {
        clearNavigationItem()

        if let navigationController = navigationController {
            UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
                animations: {
                    self.view.alpha = 0.0
                    navigationController.view.alpha = 0.0
                    navigationController.view.frame = self.hiddenNavigationControllerFrame
                },
                completion: nil
            )
        }
    }
}
