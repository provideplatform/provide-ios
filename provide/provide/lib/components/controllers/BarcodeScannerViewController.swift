//
//  BarcodeScannerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import AVFoundation

@objc
protocol BarcodeScannerViewControllerDelegate {
    func barcodeScannerViewController(_ viewController: BarcodeScannerViewController, didOutputMetadataObjects metadataObjects: [AnyObject], fromConnection connection: AVCaptureConnection)
    func barcodeScannerViewControllerShouldBeDismissed(_ viewController: BarcodeScannerViewController)
    @objc optional func rectOfInterestForBarcodeScannerViewController(_ viewController: BarcodeScannerViewController) -> CGRect
}

class BarcodeScannerViewController: ViewController, BarcodeScannerViewDelegate {

    var delegate: BarcodeScannerViewControllerDelegate! {
        didSet {
            setupBarcodeScannerView()
        }
    }

    @IBOutlet fileprivate weak var barcodeScannerView: BarcodeScannerView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let navigationController = navigationController {
            navigationController.navigationBar.tintColor = Color.applicationDefaultBarTintColor()
        }

        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(BarcodeScannerViewController.dismiss(_:)))
        view.addGestureRecognizer(swipeGestureRecognizer)

        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        setupBarcodeScannerView()
    }

    func setupBarcodeScannerView() {
        if let barcodeScannerView = barcodeScannerView {
            barcodeScannerView.frame = view.frame
            barcodeScannerView.delegate = self

            if !barcodeScannerView.isRunning {
                barcodeScannerView.startScanner()
            }
        }

    }

    func dismiss(_: UISwipeGestureRecognizer) {
        delegate?.barcodeScannerViewControllerShouldBeDismissed(self)
    }

    func stopScanner() {
        if let barcodeScannerView = barcodeScannerView {
            if barcodeScannerView.isRunning {
                barcodeScannerView.stopScanner()
            }
        }
    }

    // MARK: BarcodeScannerViewDelegate

    func barcodeScannerView(_ barcodeScannerView: BarcodeScannerView, didOutputMetadataObjects metadataObjects: [AnyObject], fromConnection connection: AVCaptureConnection) {
        delegate?.barcodeScannerViewController(self, didOutputMetadataObjects: metadataObjects, fromConnection: connection)
    }

    func rectOfInterestForBarcodeScannerView(_ barcodeScannerView: BarcodeScannerView) -> CGRect {
        if let rectOfInterest = delegate?.rectOfInterestForBarcodeScannerViewController?(self) {
            return rectOfInterest
        }
        return CGRect.zero
    }
}
