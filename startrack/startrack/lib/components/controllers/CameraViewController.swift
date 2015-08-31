
//
//  CameraViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/19/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit
import AVFoundation

protocol CameraViewControllerDelegate {
    func outputModeForCameraViewController(viewController: CameraViewController) -> CameraOutputMode
    func cameraViewControllerCanceled(viewController: CameraViewController)

    func cameraViewControllerDidBeginAsyncStillImageCapture(viewController: CameraViewController)
    func cameraViewController(viewController: CameraViewController, didCaptureStillImage image: UIImage)

    func cameraViewController(viewController: CameraViewController, didSelectImageFromCameraRoll image: UIImage)
    func cameraViewController(cameraViewController: CameraViewController, didStartVideoCaptureAtURL fileURL: NSURL)
    func cameraViewController(cameraViewController: CameraViewController, didFinishVideoCaptureAtURL fileURL: NSURL)

    func cameraViewControllerShouldOutputFaceMetadata(viewController: CameraViewController) -> Bool
    func cameraViewControllerShouldRenderFacialRecognition(viewController: CameraViewController) -> Bool
    func cameraViewControllerDidOutputFaceMetadata(viewController: CameraViewController, metadataFaceObject: AVMetadataFaceObject)
}

class CameraViewController: ViewController, CameraViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var delegate: CameraViewControllerDelegate!
    var mode: ActiveDeviceCapturePosition = .Back
    var outputMode: CameraOutputMode = .Photo

    @IBOutlet private weak var backCameraView: CameraView!
    @IBOutlet private weak var frontCameraView: CameraView!

    @IBOutlet private weak var button: UIButton!

    private var activeCameraView: CameraView! {
        switch mode {
        case .Back:
            return backCameraView
        case .Front:
            return frontCameraView
        }
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

        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "dismiss:")
        view.addGestureRecognizer(swipeGestureRecognizer)

        view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)

        setupCameraUI()
        setupBackCameraView()
    }

    func setupCameraUI() {
        view.bringSubviewToFront(button)

        button.addTarget(self, action: "capture", forControlEvents: .TouchUpInside)
        let events = UIControlEvents.TouchUpInside.union(.TouchUpOutside).union(.TouchCancel).union(.TouchDragExit)
        button.addTarget(self, action: "renderDefaultButtonAppearance", forControlEvents: events)
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

        button.enabled = true
    }

    func capture() {
        button.enabled = false
        activeCameraView?.capture()
    }

    func setupNavigationItem() {
        navigationItem.title = "TAKE PHOTO"
        navigationItem.hidesBackButton = true

        let cancelItem = UIBarButtonItem(title: "CANCEL", style: .Plain, target: self, action: "dismiss:")
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

    func dismiss(sender: UIBarButtonItem) {
        delegate?.cameraViewControllerCanceled(self)
    }

    func renderDefaultButtonAppearance() {
        button.backgroundColor = UIColor.resizedColorWithPatternImage(Color.annotationViewBackgroundImage(), rect: button.bounds).colorWithAlphaComponent(0.75)
    }

    func renderTappedButtonAppearance() {
        button.backgroundColor = UIColor.resizedColorWithPatternImage(Color.annotationViewBackgroundImage(), rect: button.bounds)
    }

    // MARK: CameraViewDelegate

    func outputModeForCameraView(cameraView: CameraView) -> CameraOutputMode {
        return outputMode
    }

    func cameraViewCaptureSessionFailedToInitializeWithError(error: NSError) {
        delegate?.cameraViewControllerCanceled(self)
    }

    func cameraViewBeganAsyncStillImageCapture(cameraView: CameraView) {
        delegate?.cameraViewControllerDidBeginAsyncStillImageCapture(self)
    }

    func cameraView(cameraView: CameraView, didCaptureStillImage image: UIImage) {
        delegate?.cameraViewController(self, didCaptureStillImage: image)
    }

    func cameraView(cameraView: CameraView, didStartVideoCaptureAtURL fileURL: NSURL) {
        delegate?.cameraViewController(self, didStartVideoCaptureAtURL: fileURL)
    }

    func cameraView(cameraView: CameraView, didFinishVideoCaptureAtURL fileURL: NSURL) {
        delegate?.cameraViewController(self, didFinishVideoCaptureAtURL: fileURL)
    }

    func cameraView(cameraView: CameraView, didMeasureAveragePower avgPower: Float, peakHold: Float, forAudioChannel channel: AVCaptureAudioChannel) {
        print("average power: \(avgPower); peak hold: \(peakHold); channel: \(channel)")
    }

    func cameraView(cameraView: CameraView, didOutputMetadataFaceObject metadataFaceObject: AVMetadataFaceObject) {
        delegate?.cameraViewControllerDidOutputFaceMetadata(self, metadataFaceObject: metadataFaceObject)
    }

    func cameraViewShouldEstablishAudioSession(cameraView: CameraView) -> Bool {
        return false
    }

    func cameraViewShouldEstablishVideoSession(cameraView: CameraView) -> Bool {
        return false
    }

    func cameraViewShouldOutputFaceMetadata(cameraView: CameraView) -> Bool {
        if let outputFaceMetadata = delegate?.cameraViewControllerShouldOutputFaceMetadata(self) {
            return outputFaceMetadata
        }
        return false
    }

    func cameraViewShouldRenderFacialRecognition(cameraView: CameraView) -> Bool {
        if let renderFacialRecognition = delegate?.cameraViewControllerShouldRenderFacialRecognition(self) {
            return renderFacialRecognition
        }
        return false
    }


}