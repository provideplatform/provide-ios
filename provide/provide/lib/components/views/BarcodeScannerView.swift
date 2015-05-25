//
//  BarcodeScannerView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation
import AVFoundation

@objc
protocol BarcodeScannerViewDelegate {

    optional func barcodeScannerView(barcodeScannerView: BarcodeScannerView!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!)
    optional func rectOfInterestForBarcodeScannerView(barcodeScannerView: BarcodeScannerView!) -> CGRect

}

class BarcodeScannerView: UIView, AVCaptureMetadataOutputObjectsDelegate {

    var delegate: BarcodeScannerViewDelegate!

    private let avMetadataOutputQueue = dispatch_queue_create("api.avMetadataOutputQueue", nil)

    private var captureInput: AVCaptureInput!
    private var captureSession: AVCaptureSession!

    @IBOutlet private weak var rectOfInterestView: UIView!

    private var capturePreviewLayer = AVCaptureVideoPreviewLayer()
    private var codeDetectionLayer = CALayer()

    override func awakeFromNib() {
        super.awakeFromNib()

        opaque = false
        backgroundColor = UIColor.clearColor()
    }

    func startScanner() {
        if captureSession != nil {
            return
        }

        if let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) {
            var error: NSError?

            if device.lockForConfiguration(&error) {
                device.focusMode = .ContinuousAutoFocus
                device.unlockForConfiguration()
            }

            var input = AVCaptureDeviceInput.deviceInputWithDevice(device, error: &error) as! AVCaptureInput

            captureSession = AVCaptureSession()
            captureSession.sessionPreset = AVCaptureSessionPresetHigh
            captureSession.addInput(input)

            var rectOfInterest = bounds
            if let customRectOfInterest = delegate?.rectOfInterestForBarcodeScannerView?(self) {
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

            var metadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: avMetadataOutputQueue)
            metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes
            metadataOutput.rectOfInterest = rectOfInterest

            captureSession.startRunning()
        }
    }

    func stopScanner() {
        if let session = captureSession {
            session.stopRunning()
            captureSession = nil
        }
    }

    // MARK: AVCaptureMetadataOutputObjectsDelegate

    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        dispatch_sync(dispatch_get_main_queue()) {
            self.clearDetectedMetadataObjects()
            self.showDetectedMetadataObjects(metadataObjects)
        }

        delegate?.barcodeScannerView?(self, didOutputMetadataObjects: metadataObjects, fromConnection: connection)
    }

    private func clearDetectedMetadataObjects() {
        codeDetectionLayer.sublayers = nil
    }

    private func showDetectedMetadataObjects(metadataObjects: [AnyObject]!) {
        for object in metadataObjects {
            if let machineReadableCodeObject = object as? AVMetadataMachineReadableCodeObject {
                if let detectedCode = capturePreviewLayer.transformedMetadataObjectForMetadataObject(machineReadableCodeObject) as? AVMetadataMachineReadableCodeObject {
                    var shapeLayer = CAShapeLayer()
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
        var path = CGPathCreateMutable()
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
