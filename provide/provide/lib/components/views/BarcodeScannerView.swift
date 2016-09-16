//
//  BarcodeScannerView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import AVFoundation
import KTSwiftExtensions

protocol BarcodeScannerViewDelegate: NSObjectProtocol {
    func barcodeScannerView(_ barcodeScannerView: BarcodeScannerView, didOutputMetadataObjects metadataObjects: [AnyObject], fromConnection connection: AVCaptureConnection)
    func rectOfInterestForBarcodeScannerView(_ barcodeScannerView: BarcodeScannerView) -> CGRect
}

class BarcodeScannerView: UIView, AVCaptureMetadataOutputObjectsDelegate {

    weak var delegate: BarcodeScannerViewDelegate!

    fileprivate let avMetadataOutputQueue = DispatchQueue(label: "api.avMetadataOutputQueue", attributes: [])

    fileprivate var captureInput: AVCaptureInput!
    fileprivate var captureSession: AVCaptureSession!

    fileprivate var capturePreviewLayer = AVCaptureVideoPreviewLayer()
    fileprivate let codeDetectionLayer = CALayer()

    override func awakeFromNib() {
        super.awakeFromNib()

        isOpaque = false
        backgroundColor = UIColor.clear
    }

    var isRunning: Bool {
        if let captureSession = captureSession {
            return captureSession.isRunning
        }
        return false
    }

    func startScanner() {
        if captureSession != nil {
            return
        }

        if let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) {
            do {
                try device.lockForConfiguration()
                device.focusMode = .continuousAutoFocus
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
                    if customRectOfInterest != CGRect.zero {
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

        if Thread.isMainThread {
            clearDetectedMetadataObjects()
        } else {
            dispatch_after_delay(0.0) {
                self.clearDetectedMetadataObjects()
            }
        }
    }

    // MARK: AVCaptureMetadataOutputObjectsDelegate

    fileprivate func captureOutput(_ captureOutput: AVCaptureOutput, didOutputMetadataObjects metadataObjects: [AnyObject], from connection: AVCaptureConnection) {
        dispatch_after_delay(0.0) {
            self.clearDetectedMetadataObjects()
            self.showDetectedMetadataObjects(metadataObjects)
        }

        delegate?.barcodeScannerView(self, didOutputMetadataObjects: metadataObjects, fromConnection: connection)
    }

    fileprivate func clearDetectedMetadataObjects() {
        codeDetectionLayer.sublayers = nil
    }

    fileprivate func showDetectedMetadataObjects(_ metadataObjects: [AnyObject]) {
        for object in metadataObjects {
            if let machineReadableCodeObject = object as? AVMetadataMachineReadableCodeObject {
                if let detectedCode = capturePreviewLayer.transformedMetadataObject(for: machineReadableCodeObject) as? AVMetadataMachineReadableCodeObject {
                    let shapeLayer = CAShapeLayer()
                    shapeLayer.strokeColor = UIColor.green.cgColor
                    shapeLayer.fillColor = UIColor.clear.cgColor
                    shapeLayer.lineWidth = 2.0
                    shapeLayer.lineJoin = kCALineJoinRound
                    shapeLayer.path = createPathForPoints(detectedCode.corners as NSArray)
                    codeDetectionLayer.addSublayer(shapeLayer)
                }
            }
        }
    }

    fileprivate func createPathForPoints(_ points: NSArray) -> CGPath {
        let path = CGMutablePath()
        var point = CGPoint.zero

        if points.count > 0 {
            point = CGPoint(dictionaryRepresentation: (points[0] as! CFDictionary))!
            path.move(to: point)

            for pointInArray in points {
                point = CGPoint(dictionaryRepresentation: (pointInArray as! CFDictionary))!
                path.addLine(to: point)
            }

            path.closeSubpath()
        }

        return path
    }
}
