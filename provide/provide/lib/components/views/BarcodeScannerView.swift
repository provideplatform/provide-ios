//
//  BarcodeScannerView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation
import AVFoundation
import KTSwiftExtensions

protocol BarcodeScannerViewDelegate: NSObjectProtocol {
    func barcodeScannerView(barcodeScannerView: BarcodeScannerView, didOutputMetadataObjects metadataObjects: [AnyObject], fromConnection connection: AVCaptureConnection)
    func rectOfInterestForBarcodeScannerView(barcodeScannerView: BarcodeScannerView) -> CGRect
}

class BarcodeScannerView: UIView, AVCaptureMetadataOutputObjectsDelegate {

    weak var delegate: BarcodeScannerViewDelegate!

    private let avMetadataOutputQueue = dispatch_queue_create("api.avMetadataOutputQueue", nil)

    private var captureInput: AVCaptureInput!
    private var captureSession: AVCaptureSession!

    private var capturePreviewLayer = AVCaptureVideoPreviewLayer()
    private let codeDetectionLayer = CALayer()

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

    func startScanner() {
        if captureSession != nil {
            return
        }

        if let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) {
            do {
                try device.lockForConfiguration()
                device.focusMode = .ContinuousAutoFocus
                device.unlockForConfiguration()
            } catch let error as NSError {
                logWarn(error.localizedDescription)
            }

            do {
                let input = try AVCaptureDeviceInput(device: device)

                captureSession = AVCaptureSession()
                captureSession.sessionPreset = AVCaptureSessionPresetHigh
                captureSession.addInput(input)

                var rectOfInterest = bounds
                if let customRectOfInterest = delegate?.rectOfInterestForBarcodeScannerView(self) {
                    if customRectOfInterest != CGRectZero {
                        rectOfInterest = customRectOfInterest
                    }
                }

                capturePreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                capturePreviewLayer.frame = rectOfInterest
                capturePreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                layer.addSublayer(capturePreviewLayer)

                codeDetectionLayer.frame = rectOfInterest
                layer.insertSublayer(codeDetectionLayer, above: capturePreviewLayer)

                let metadataOutput = AVCaptureMetadataOutput()
                captureSession.addOutput(metadataOutput)

                let overlayImageView = UIImageView(image: UIImage("scanner-overlay"))
                overlayImageView.frame = CGRect(x: 25.0,
                                                y: (rectOfInterest.height / 4.0) + 50.0,
                                                width: rectOfInterest.width - 50.0,
                                                height: rectOfInterest.height / 4.0)

                layer.insertSublayer(overlayImageView.layer, above: capturePreviewLayer)

                metadataOutput.setMetadataObjectsDelegate(self, queue: avMetadataOutputQueue)
                metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes
                metadataOutput.rectOfInterest = rectOfInterest
                
                captureSession.startRunning()
            } catch let error as NSError {
                logWarn(error.localizedDescription)
            }
        }
    }

    func stopScanner() {
        if let session = captureSession {
            session.stopRunning()
            captureSession = nil
        }

        if NSThread.isMainThread() {
            clearDetectedMetadataObjects()
        } else {
            dispatch_after_delay(0.0) {
                self.clearDetectedMetadataObjects()
            }
        }
    }

    // MARK: AVCaptureMetadataOutputObjectsDelegate

    func captureOutput(captureOutput: AVCaptureOutput, didOutputMetadataObjects metadataObjects: [AnyObject], fromConnection connection: AVCaptureConnection) {
        dispatch_after_delay(0.0) {
            self.clearDetectedMetadataObjects()
            self.showDetectedMetadataObjects(metadataObjects)
        }

        delegate?.barcodeScannerView(self, didOutputMetadataObjects: metadataObjects, fromConnection: connection)
    }

    private func clearDetectedMetadataObjects() {
        codeDetectionLayer.sublayers = nil
    }

    private func showDetectedMetadataObjects(metadataObjects: [AnyObject]) {
        for object in metadataObjects {
            if let machineReadableCodeObject = object as? AVMetadataMachineReadableCodeObject {
                if let detectedCode = capturePreviewLayer.transformedMetadataObjectForMetadataObject(machineReadableCodeObject) as? AVMetadataMachineReadableCodeObject {
                    let shapeLayer = CAShapeLayer()
                    shapeLayer.strokeColor = UIColor.greenColor().CGColor
                    shapeLayer.fillColor = UIColor.clearColor().CGColor
                    shapeLayer.lineWidth = 2.0
                    shapeLayer.lineJoin = kCALineJoinRound
                    shapeLayer.path = createPathForPoints(detectedCode.corners)
                    codeDetectionLayer.addSublayer(shapeLayer)
                }
            }
        }
    }

    private func createPathForPoints(points: NSArray) -> CGPath {
        let path = CGPathCreateMutable()
        var point = CGPointZero

        if points.count > 0 {
            CGPointMakeWithDictionaryRepresentation((points[0] as! CFDictionaryRef), &point)
            CGPathMoveToPoint(path, nil, point.x, point.y)

            for pointInArray in points {
                CGPointMakeWithDictionaryRepresentation((pointInArray as! CFDictionaryRef), &point)
                CGPathAddLineToPoint(path, nil, point.x, point.y)
            }

            CGPathCloseSubpath(path)
        }

        return path
    }
}
