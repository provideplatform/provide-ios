//
//  SelfieViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol SelfieViewControllerDelegate {
    func selfieViewController(viewController: SelfieViewController, didCaptureStillImage image: UIImage)
    func selfieViewControllerCanceled(viewController: SelfieViewController)
}

class SelfieViewController: ViewController, CameraViewDelegate {

    var delegate: SelfieViewControllerDelegate!

    @IBOutlet private weak var cameraView: CameraView!
    @IBOutlet private weak var button: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationItem()

        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "dismiss")
        view.addGestureRecognizer(swipeGestureRecognizer)

        view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)

        setupCameraUI()

        setupCameraView()
    }

    func setupCameraUI() {
        view.bringSubviewToFront(button)

        button.addTarget(cameraView, action: "captureFrame", forControlEvents: .TouchUpInside)
        button.addTarget(self, action: "renderDefaultButtonAppearance", forControlEvents: [.TouchUpInside, .TouchUpOutside, .TouchCancel, .TouchDragExit])
        button.addTarget(self, action: "renderTappedButtonAppearance", forControlEvents: .TouchDown)

        button.addBorder(5.0, color: UIColor.whiteColor())
        button.makeCircular()

        renderDefaultButtonAppearance()
    }

    func setupNavigationItem() {
        navigationItem.title = "TAKE A SELFIE!"
        navigationItem.hidesBackButton = true

        let cancelItem = UIBarButtonItem.plainBarButtonItem(title: "SKIP", target: self, action: "dismiss")
        navigationItem.leftBarButtonItems = [cancelItem]
    }

    func setupCameraView() {
        cameraView?.frame = view.frame
        cameraView?.delegate = self
        cameraView?.startCapture()
    }

    func dismiss() {
        delegate?.selfieViewControllerCanceled(self)
    }

    func renderDefaultButtonAppearance() {
        button.backgroundColor = UIColor.resizedColorWithPatternImage(Color.annotationViewBackgroundImage(), rect: button.bounds).colorWithAlphaComponent(0.75)
    }

    func renderTappedButtonAppearance() {
        button.backgroundColor = UIColor.resizedColorWithPatternImage(Color.annotationViewBackgroundImage(), rect: button.bounds)
    }

    func cameraView(cameraView: CameraView, didCaptureStillImage image: UIImage) {
        delegate?.selfieViewController(self, didCaptureStillImage: image)
    }
}
