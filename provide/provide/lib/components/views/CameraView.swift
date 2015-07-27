//
//  CameraView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation
import AVFoundation

@objc
protocol CameraViewDelegate {

    func cameraView(cameraView: CameraView, didCaptureStillImage image: UIImage)
    optional func cameraViewShouldOutputFaceMetadata(cameraView: CameraView) -> Bool
    optional func cameraViewShouldRenderFacialRecognition(cameraView: CameraView) -> Bool
}

class CameraView: UIView, AVCaptureMetadataOutputObjectsDelegate {

    var delegate: CameraViewDelegate!

    private let avCameraOutputQueue = dispatch_queue_create("api.avCameraOutputQueue", nil)
    private let avMetadataFaceOutputQueue = dispatch_queue_create("api.avMetadataFaceOutputQueue", nil)

    private var captureInput: AVCaptureInput!
    private var captureSession: AVCaptureSession!

    private var capturePreviewLayer = AVCaptureVideoPreviewLayer()
    private let codeDetectionLayer = CALayer()

    private var stillCameraOutput: AVCaptureStillImageOutput!

    private var backCamera: AVCaptureDevice! {
        for device in AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) {
            if device.position == .Back {
                return device as! AVCaptureDevice
            }
        }
        return nil
    }

    private var frontCamera: AVCaptureDevice! {
        for device in AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) {
            if device.position == .Front {
                return device as? AVCaptureDevice
            }
        }
        return nil
    }

    private var outputFaceMetadata: Bool {
        if let delegate = delegate {
            if let outputFaceMetadata = delegate.cameraViewShouldOutputFaceMetadata?(self) {
                return outputFaceMetadata
            }
        }
        return false
    }

    private var renderFacialRecognition: Bool {
        if let delegate = delegate {
            if let renderFacialRecognition = delegate.cameraViewShouldRenderFacialRecognition?(self) {
                return renderFacialRecognition
            }
        }
        return false
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        opaque = false
        backgroundColor = UIColor.clearColor()
    }

    var isRunning: Bool {
        if let captureSession = captureSession {
            return captureSession.running
        }
        return false
    }

    func startBackCameraCapture() {
        startCapture(backCamera)
    }

    func startFrontCameraCapture() {
        startCapture(frontCamera)
    }

    func startCapture(device: AVCaptureDevice) {
        if captureSession != nil {
            stopCapture()
        }

        var error: NSError?

        if device.lockForConfiguration(&error) {
            if device.isFocusModeSupported(.ContinuousAutoFocus) {
                device.focusMode = .ContinuousAutoFocus
            } else if device.isFocusModeSupported(.AutoFocus) {
                device.focusMode = .AutoFocus
            }

            device.unlockForConfiguration()
        }

        if let error = error {
            logError(error)
        }

        let input = AVCaptureDeviceInput(device: device, error: &error)

        if let error = error {
            logError(error)
        }

        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSessionPresetHigh
        captureSession.addInput(input)

        capturePreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        capturePreviewLayer.frame = bounds
        capturePreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        layer.addSublayer(capturePreviewLayer)

        stillCameraOutput = AVCaptureStillImageOutput()
        if captureSession.canAddOutput(stillCameraOutput) {
            captureSession.addOutput(stillCameraOutput)
        }

        if outputFaceMetadata {
            let metadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: avMetadataFaceOutputQueue)
            metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes
            metadataOutput.rectOfInterest = bounds
        }

        if renderFacialRecognition {
            codeDetectionLayer.frame = bounds
            layer.insertSublayer(codeDetectionLayer, above: capturePreviewLayer)
        }

        captureSession.startRunning()
    }

    func stopCapture() {
        if let session = captureSession {
            session.stopRunning()
            captureSession = nil
        }

        if let previewLayer = capturePreviewLayer {
            previewLayer.removeFromSuperlayer()
            capturePreviewLayer = nil
        }
    }

    @objc func captureFrame(_: UIButton) {
        if isSimulator() {
            if let window = UIApplication.sharedApplication().keyWindow {
                UIGraphicsBeginImageContextWithOptions(window.bounds.size, false, UIScreen.mainScreen().scale)
                window.layer.renderInContext(UIGraphicsGetCurrentContext())
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                delegate?.cameraView(self, didCaptureStillImage: image)
            }
            return
        }

        dispatch_async(avCameraOutputQueue) {
            if let cameraOutput = self.stillCameraOutput {
                let connection = cameraOutput.connectionWithMediaType(AVMediaTypeVideo)
                connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)!

                cameraOutput.captureStillImageAsynchronouslyFromConnection(connection) { imageDataSampleBuffer, error in
                    if error == nil {
                        let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)

                        if let image = UIImage(data: imageData) {
                            self.delegate?.cameraView(self, didCaptureStillImage: image)
                        }
                    } else {
                        logError("Error capturing still image \(error)")
                    }
                }
            }
        }
    }

    // MARK: AVCaptureMetadataOutputObjectsDelegate

    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        if renderFacialRecognition {
            dispatch_after_delay(0.0) {
                self.clearDetectedMetadataObjects()
                self.showDetectedMetadataObjects(metadataObjects)
            }
        }

        // TODO-- set up-to-date rect for faces
    }

    private func clearDetectedMetadataObjects() {
        if let codeDetectionLayer = codeDetectionLayer {
            codeDetectionLayer.sublayers = nil
        }
    }

    private func showDetectedMetadataObjects(metadataObjects: [AnyObject]!) {
        for object in metadataObjects {
            if let metadataFaceObject = object as? AVMetadataFaceObject {
                if let detectedCode = capturePreviewLayer.transformedMetadataObjectForMetadataObject(metadataFaceObject) as? AVMetadataFaceObject {
                    let shapeLayer = CAShapeLayer()
                    shapeLayer.strokeColor = UIColor.greenColor().CGColor
                    shapeLayer.fillColor = UIColor.clearColor().CGColor
                    shapeLayer.lineWidth = 2.0
                    shapeLayer.lineJoin = kCALineJoinRound
                    shapeLayer.path = UIBezierPath(rect: detectedCode.bounds).CGPath
                    codeDetectionLayer.addSublayer(shapeLayer)
                }
            }
        }
    }
}
