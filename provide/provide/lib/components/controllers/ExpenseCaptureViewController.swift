//
//  ExpenseCaptureViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/5/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit
import AVFoundation

protocol ExpenseCaptureViewControllerDelegate {
    func expenseCaptureViewController(viewController: ExpenseCaptureViewController, didCaptureReceipt receipt: UIImage, recognizedTexts texts: [String]!)
}

class ExpenseCaptureViewController: CameraViewController, CameraViewControllerDelegate {

    var expenseCaptureViewControllerDelegate: ExpenseCaptureViewControllerDelegate!

    private var recognizedTexts = [String]()

    override func awakeFromNib() {
        super.awakeFromNib()

        delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationItem()

        view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)

        
    }

    override func setupNavigationItem() {
        navigationItem.title = "CAPTURE RECEIPT"
        navigationItem.hidesBackButton = true

        navigationItem.leftBarButtonItem = UIBarButtonItem.plainBarButtonItem(title: "CANCEL", target: self, action: "dismiss:")
    }

    // MARK: CameraViewControllerDelegate

    func outputModeForCameraViewController(viewController: CameraViewController) -> CameraOutputMode {
        return .Photo
    }

    func cameraViewControllerCanceled(viewController: CameraViewController) {
        if let presentingViewController = presentingViewController {
            presentingViewController.dismissViewController(animated: true)
        }
    }

    func cameraViewControllerDidBeginAsyncStillImageCapture(viewController: CameraViewController) {

    }

    func cameraViewController(viewController: CameraViewController, didCaptureStillImage image: UIImage) {
        expenseCaptureViewControllerDelegate?.expenseCaptureViewController(self, didCaptureReceipt: image, recognizedTexts: recognizedTexts)
        cameraViewControllerCanceled(self)
    }

    func cameraViewController(viewController: CameraViewController, didSelectImageFromCameraRoll image: UIImage) {

    }

    func cameraViewController(cameraViewController: CameraViewController, didStartVideoCaptureAtURL fileURL: NSURL) {

    }

    func cameraViewController(cameraViewController: CameraViewController, didFinishVideoCaptureAtURL fileURL: NSURL) {

    }

    func cameraViewControllerShouldOutputFaceMetadata(viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerShouldOutputOCRMetadata(viewController: CameraViewController) -> Bool {
        return true
    }

    func cameraViewControllerShouldRenderFacialRecognition(viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerDidOutputFaceMetadata(viewController: CameraViewController, metadataFaceObject: AVMetadataFaceObject) {

    }

    func cameraViewController(viewController: CameraViewController, didRecognizeText text: String!) {
        recognizedTexts.append(text)
    }
}
