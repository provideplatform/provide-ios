//
//  CameraViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/19/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

@objc
protocol CameraViewControllerDelegate {
    func cameraViewController(viewController: CameraViewController!, didCaptureStillImage image: UIImage!)
    func cameraViewControllerCanceled(viewController: CameraViewController!)
    optional func cameraViewControllerShouldOutputFaceMetadata(viewController: CameraViewController!) -> Bool
    optional func cameraViewControllerShouldRenderFacialRecognition(viewController: CameraViewController!) -> Bool
}

class CameraViewController: ViewController, CameraViewDelegate {

    enum ActiveCameraMode {
        case Back, Front
    }

    var delegate: CameraViewControllerDelegate!
    var mode: ActiveCameraMode = .Back

    @IBOutlet private weak var backCameraView: CameraView!
    @IBOutlet private weak var frontCameraView: CameraView!

    @IBOutlet private weak var button: UIButton!

    private var activeCameraView: CameraView! {
        switch mode {
        case .Back:
            return backCameraView
        case .Front:
            return frontCameraView
        default:
            break
        }
        return nil
    }

    var isRunning: Bool {
        if let backCameraView = backCameraView {
            if backCameraView.isRunning {
                return true
            }
        }

        if let frontCameraView = frontCameraView {
            if frontCameraView.isRunning {
                return true
            }
        }

        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationItem()

        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "dismiss")
        view.addGestureRecognizer(swipeGestureRecognizer)

        view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)

        setupCameraUI()
        setupBackCameraView()
    }

    func setupCameraUI() {
        view.bringSubviewToFront(button)

        button.addTarget(self, action: "captureFrame", forControlEvents: .TouchUpInside)
        button.addTarget(self, action: "renderDefaultButtonAppearance", forControlEvents: .TouchUpInside | .TouchUpOutside | .TouchCancel | .TouchDragExit)
        button.addTarget(self, action: "renderTappedButtonAppearance", forControlEvents: .TouchDown)

        button.addBorder(5.0, color: UIColor.whiteColor())
        button.makeCircular()

        renderDefaultButtonAppearance()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)

        if !isRunning {
            setupBackCameraView()
        }
    }

    func captureFrame() {
        activeCameraView?.captureFrame()
    }

    func setupNavigationItem() {
        navigationItem.title = "TAKE PHOTO"
        navigationItem.hidesBackButton = true

        let cancelItem = UIBarButtonItem(title: "CANCEL", style: .Plain, target: self, action: "dismiss")
        cancelItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)

        navigationItem.leftBarButtonItems = [cancelItem]
    }

    func setupBackCameraView() {
        mode = .Back

        if let backCameraView = backCameraView {
            backCameraView.frame = view.frame
            backCameraView.delegate = self
            backCameraView.startBackCameraCapture()

            view.bringSubviewToFront(backCameraView)
        }

        view.bringSubviewToFront(button)
    }

    func setupFrontCameraView() {
        mode = .Front

        if let frontCameraView = frontCameraView {
            frontCameraView.frame = view.frame
            frontCameraView.delegate = self
            frontCameraView.startFrontCameraCapture()

            view.bringSubviewToFront(frontCameraView)
        }

        view.bringSubviewToFront(button)
    }

    func teardownBackCameraView() {
        backCameraView?.stopCapture()
    }

    func teardownFrontCameraView() {
        frontCameraView?.stopCapture()
    }

    func cameraView(cameraView: CameraView!, didCaptureStillImage image: UIImage!) {
        delegate?.cameraViewController(self, didCaptureStillImage: image)
    }

    func cameraViewShouldOutputFaceMetadata(cameraView: CameraView) -> Bool {
        if let outputFaceMetadata = delegate?.cameraViewControllerShouldOutputFaceMetadata?(self) {
            return outputFaceMetadata
        }
        return false
    }

    func cameraViewShouldRenderFacialRecognition(cameraView: CameraView) -> Bool {
        if let renderFacialRecognition = delegate?.cameraViewControllerShouldRenderFacialRecognition?(self) {
            return renderFacialRecognition
        }
        return false
    }

    func dismiss() {
        delegate?.cameraViewControllerCanceled(self)
    }

    func renderDefaultButtonAppearance() {
        button.backgroundColor = UIColor.resizedColorWithPatternImage(Color.annotationViewBackgroundImage(), rect: button.bounds).colorWithAlphaComponent(0.75)
    }

    func renderTappedButtonAppearance() {
        button.backgroundColor = UIColor.resizedColorWithPatternImage(Color.annotationViewBackgroundImage(), rect: button.bounds)
    }
}
