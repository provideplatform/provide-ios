//
//  CameraView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation
import AVFoundation

protocol CameraViewDelegate {

    func cameraView(cameraView: CameraView, didCaptureStillImage image: UIImage)
}

class CameraView: UIView {

    var delegate: CameraViewDelegate!

    private let avCameraOutputQueue = dispatch_queue_create("api.avCameraOutputQueue", nil)

    private var captureInput: AVCaptureInput!
    private var captureSession: AVCaptureSession!

    private var capturePreviewLayer = AVCaptureVideoPreviewLayer()

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
}
