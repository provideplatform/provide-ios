//
//  BarcodeScannerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit
import AVFoundation

@objc
protocol BarcodeScannerViewControllerDelegate {

    optional func barcodeScannerViewController(viewController: BarcodeScannerViewController!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!)
    optional func barcodeScannerViewControllerShouldBeDismissed(viewController: BarcodeScannerViewController!)
    optional func rectOfInterestForBarcodeScannerViewController(viewController: BarcodeScannerViewController!) -> CGRect

}

class BarcodeScannerViewController: ViewController, BarcodeScannerViewDelegate {

    var delegate: BarcodeScannerViewControllerDelegate! {
        didSet {
            setupBarcodeScannerView()
        }
    }

    @IBOutlet private weak var barcodeScannerView: BarcodeScannerView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "dismiss")
        view.addGestureRecognizer(swipeGestureRecognizer)

        view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)

        setupBarcodeScannerView()
    }

    func setupBarcodeScannerView() {
        barcodeScannerView?.frame = view.frame
        barcodeScannerView?.delegate = self
        barcodeScannerView?.startScanner()
    }

    func dismiss() {
        delegate?.barcodeScannerViewControllerShouldBeDismissed?(self)
    }

    func stopScanner() {
        barcodeScannerView?.stopScanner()
    }

    // MARK: BarcodeScannerViewDelegate

    func barcodeScannerView(barcodeScannerView: BarcodeScannerView!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        delegate?.barcodeScannerViewController?(self, didOutputMetadataObjects: metadataObjects, fromConnection: connection)
    }

    func rectOfInterestForBarcodeScannerView(barcodeScannerView: BarcodeScannerView!) -> CGRect {
        if let rectOfInterest = delegate?.rectOfInterestForBarcodeScannerViewController?(self) {
            return rectOfInterest
        }
        return CGRectZero
    }

}
