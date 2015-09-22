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
    func barcodeDataForBarcodeViewController(viewController: QRCodeViewController) -> String
}

class QRCodeViewController: WorkOrderComponentViewController {

    var qrCodeViewControllerDelegate: QRCodeViewControllerDelegate! {
        didSet {
            if let delegate = qrCodeViewControllerDelegate {
                let data = delegate.barcodeDataForBarcodeViewController(self)
                qrCodeImage = UIImage.qrCodeImageWithString(data)
            } else {
                qrCodeImage = nil
            }
        }
    }

    @IBOutlet private weak var qrCodeImageView: UIImageView!

    private var qrCodeImage: UIImage! {
        didSet {
            if let qrCodeImage = qrCodeImage {
                qrCodeImageView?.image = qrCodeImage
            } else {
                qrCodeImageView?.image = nil
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
