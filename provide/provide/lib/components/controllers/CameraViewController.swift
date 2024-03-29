//
//  CameraViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/19/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import AVFoundation

protocol CameraViewControllerDelegate: class {
    func outputModeForCameraViewController(_ viewController: CameraViewController) -> CameraOutputMode
    func cameraViewControllerCanceled(_ viewController: CameraViewController)

    func cameraViewControllerDidBeginAsyncStillImageCapture(_ viewController: CameraViewController)
    func cameraViewController(_ viewController: CameraViewController, didCaptureStillImage image: UIImage)

    func cameraViewController(_ viewController: CameraViewController, didSelectImageFromCameraRoll image: UIImage)
    func cameraViewController(_ cameraViewController: CameraViewController, didStartVideoCaptureAtURL fileURL: URL)
    func cameraViewController(_ cameraViewController: CameraViewController, didFinishVideoCaptureAtURL fileURL: URL)

    func cameraViewControllerShouldOutputFaceMetadata(_ viewController: CameraViewController) -> Bool
    func cameraViewControllerShouldOutputOCRMetadata(_ viewController: CameraViewController) -> Bool
    func cameraViewControllerShouldRenderFacialRecognition(_ viewController: CameraViewController) -> Bool
    func cameraViewControllerDidOutputFaceMetadata(_ viewController: CameraViewController, metadataFaceObject: AVMetadataFaceObject)
    func cameraViewController(_ viewController: CameraViewController, didRecognizeText text: String!)
}

class CameraViewController: ViewController, CameraViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    weak var delegate: CameraViewControllerDelegate?
    private var mode: ActiveDeviceCapturePosition = .back
    private var outputMode: CameraOutputMode = .photo

    @IBOutlet private weak var backCameraView: CameraView!
    @IBOutlet private weak var frontCameraView: CameraView!

    @IBOutlet private weak var button: UIButton!

    private var activeCameraView: CameraView! {
        switch mode {
        case .back:
            return backCameraView
        case .front:
            return frontCameraView
        }
    }

    private var isRunning: Bool {
        if let backCameraView = backCameraView, backCameraView.isRunning {
            return true
        }

        if let frontCameraView = frontCameraView, frontCameraView.isRunning {
            return true
        }

        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationItem()

        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(dismiss(_:)))
        view.addGestureRecognizer(swipeGestureRecognizer)

        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        setupCameraUI()
        setupBackCameraView()
    }

    func setupCameraUI() {
        guard let button = button else { return }

        view.bringSubview(toFront: button)

        button.addTarget(self, action: #selector(capture), for: .touchUpInside)
        let events = UIControlEvents.touchUpInside.union(.touchUpOutside).union(.touchCancel).union(.touchDragExit)
        button.addTarget(self, action: #selector(renderDefaultButtonAppearance), for: events)
        button.addTarget(self, action: #selector(renderTappedButtonAppearance), for: .touchDown)

        button.addBorder(5.0, color: .white)
        button.makeCircular()

        renderDefaultButtonAppearance()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)

        if !isRunning {
            setupBackCameraView()
        }

        button?.isEnabled = true

        DispatchQueue.main.async {
            self.button?.frame.origin.y = self.view.height - 8.0 - self.button.frame.height
        }
    }

    deinit {
        activeCameraView?.stopCapture()
    }

    @objc func capture() {
        button?.isEnabled = false
        activeCameraView?.capture()
    }

    func setupNavigationItem() {
        navigationItem.title = "TAKE PHOTO"
        navigationItem.hidesBackButton = true

        let cancelItem = UIBarButtonItem(title: "CANCEL", style: .plain, target: self, action: #selector(dismiss(_:)))
        cancelItem.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), for: UIControlState())

        navigationItem.leftBarButtonItems = [cancelItem]
    }

    func setupBackCameraView() {
        mode = .back

        if let backCameraView = backCameraView {
            backCameraView.frame = view.frame
            backCameraView.delegate = self
            backCameraView.startBackCameraCapture()

            backCameraView.setCapturePreviewOrientationWithDeviceOrientation(UIDevice.current.orientation, size: view.frame.size)

            view.bringSubview(toFront: backCameraView)
        }

        if let button = button {
            view.bringSubview(toFront: button)
        }
    }

    func setupFrontCameraView() {
        mode = .front

        if let frontCameraView = frontCameraView {
            frontCameraView.frame = view.frame
            frontCameraView.delegate = self
            frontCameraView.startFrontCameraCapture()

            frontCameraView.setCapturePreviewOrientationWithDeviceOrientation(UIDevice.current.orientation, size: view.frame.size)

            view.bringSubview(toFront: frontCameraView)
        }

        if let button = button {
            view.bringSubview(toFront: button)
        }
    }

    func teardownBackCameraView() {
        backCameraView?.stopCapture()
    }

    func teardownFrontCameraView() {
        frontCameraView?.stopCapture()
    }

    @objc func dismiss(_ sender: UIBarButtonItem) {
        delegate?.cameraViewControllerCanceled(self)
    }

    @objc func renderDefaultButtonAppearance() {
        button?.backgroundColor = UIColor.resizedColorWithPatternImage(Color.annotationViewBackgroundImage(), rect: button.bounds).withAlphaComponent(0.75)
    }

    @objc func renderTappedButtonAppearance() {
        button?.backgroundColor = UIColor.resizedColorWithPatternImage(Color.annotationViewBackgroundImage(), rect: button.bounds).withAlphaComponent(0.75)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        DispatchQueue.main.async {
            self.button?.frame.origin.y = self.view.height - 8.0 - self.button.frame.height
            self.activeCameraView?.setCapturePreviewOrientationWithDeviceOrientation(UIDevice.current.orientation, size: size)
        }
    }

    // MARK: CameraViewDelegate

    func outputModeForCameraView(_ cameraView: CameraView) -> CameraOutputMode {
        return delegate?.outputModeForCameraViewController(self) ?? outputMode
    }

    func cameraViewCaptureSessionFailedToInitializeWithError(_ error: NSError) {
        delegate?.cameraViewControllerCanceled(self)
    }

    func cameraViewBeganAsyncStillImageCapture(_ cameraView: CameraView) {
        delegate?.cameraViewControllerDidBeginAsyncStillImageCapture(self)
    }

    func cameraView(_ cameraView: CameraView, didCaptureStillImage image: UIImage) {
        delegate?.cameraViewController(self, didCaptureStillImage: image)
    }

    func cameraView(_ cameraView: CameraView, didStartVideoCaptureAtURL fileURL: URL) {
        delegate?.cameraViewController(self, didStartVideoCaptureAtURL: fileURL)
    }

    func cameraView(_ cameraView: CameraView, didFinishVideoCaptureAtURL fileURL: URL) {
        delegate?.cameraViewController(self, didFinishVideoCaptureAtURL: fileURL)
    }

    func cameraView(_ cameraView: CameraView, didMeasureAveragePower avgPower: Float, peakHold: Float, forAudioChannel channel: AVCaptureAudioChannel) {
        logInfo("Camera view measured average power: \(avgPower); peak hold: \(peakHold); channel: \(channel)")
    }

    func cameraView(_ cameraView: CameraView, didOutputMetadataFaceObject metadataFaceObject: AVMetadataFaceObject) {
        delegate?.cameraViewControllerDidOutputFaceMetadata(self, metadataFaceObject: metadataFaceObject)
    }

    func cameraViewShouldEstablishAudioSession(_ cameraView: CameraView) -> Bool {
        return false
    }

    func cameraViewShouldEstablishVideoSession(_ cameraView: CameraView) -> Bool {
        return outputModeForCameraView(cameraView) == .videoSampleBuffer
    }

    func cameraViewShouldOutputFaceMetadata(_ cameraView: CameraView) -> Bool {
        return delegate?.cameraViewControllerShouldOutputFaceMetadata(self) ?? false
    }

    func cameraViewShouldOutputOCRMetadata(_ cameraView: CameraView) -> Bool {
        return delegate?.cameraViewControllerShouldOutputOCRMetadata(self) ?? false
    }

    func cameraViewShouldRenderFacialRecognition(_ cameraView: CameraView) -> Bool {
        return delegate?.cameraViewControllerShouldRenderFacialRecognition(self) ?? false
    }

    func cameraView(_ cameraView: CameraView, didRecognizeText text: String!) {
        delegate?.cameraViewController(self, didRecognizeText: text)
    }
}
