//
//  CameraView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation
import AVFoundation

enum ActiveDeviceCapturePosition {
    case Back, Front
}

enum CameraOutputMode {
    case Audio
    case Video
    case VideoSampleBuffer
    case Photo
    case Selfie
}

protocol CameraViewDelegate {
    func outputModeForCameraView(cameraView: CameraView) -> CameraOutputMode
    func cameraView(cameraView: CameraView, didCaptureStillImage image: UIImage)
    func cameraView(cameraView: CameraView, didStartVideoCaptureAtURL fileURL: NSURL)
    func cameraView(cameraView: CameraView, didFinishVideoCaptureAtURL fileURL: NSURL)
    func cameraView(cameraView: CameraView, didMeasureAveragePower avgPower: Float, peakHold: Float, forAudioChannel channel: AVCaptureAudioChannel)
    func cameraView(cameraView: CameraView, didOutputMetadataFaceObject metadataFaceObject: AVMetadataFaceObject)

    func cameraViewShouldEstablishAudioSession(cameraView: CameraView) -> Bool
    func cameraViewShouldEstablishVideoSession(cameraView: CameraView) -> Bool
    func cameraViewShouldOutputFaceMetadata(cameraView: CameraView) -> Bool
    func cameraViewShouldRenderFacialRecognition(cameraView: CameraView) -> Bool
}

class CameraView: UIView, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate, AVCaptureMetadataOutputObjectsDelegate {

    var delegate: CameraViewDelegate!

    private let avAudioOutputQueue = dispatch_queue_create("api.avAudioOutputQueue", DISPATCH_QUEUE_SERIAL)
    private let avCameraOutputQueue = dispatch_queue_create("api.avCameraOutputQueue", DISPATCH_QUEUE_SERIAL)
    private let avMetadataOutputQueue = dispatch_queue_create("api.avMetadataOutputQueue", DISPATCH_QUEUE_SERIAL)
    private let avVideoOutputQueue = dispatch_queue_create("api.avVideoOutputQueue", DISPATCH_QUEUE_SERIAL)

    private var captureInput: AVCaptureInput!
    private var captureSession: AVCaptureSession!

    private var capturePreviewLayer = AVCaptureVideoPreviewLayer()
    private var codeDetectionLayer: CALayer!

    private var audioDataOutput: AVCaptureAudioDataOutput!
    private var audioLevelsPollingTimer: NSTimer!

    private var videoDataOutput: AVCaptureVideoDataOutput!
    private var videoFileOutput: AVCaptureMovieFileOutput!

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

    var isRunning: Bool {
        if let captureSession = captureSession {
            return captureSession.running
        }
        return false
    }

    private var mic: AVCaptureDevice! {
        get {
            return AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        }
    }

    private var outputFaceMetadata: Bool {
        if let delegate = delegate {
            return delegate.cameraViewShouldOutputFaceMetadata(self)
        }
        return false
    }

    private var recording = false {
        didSet {
            if recording == true {
                startAudioLevelsPollingTimer()
            } else {
                stopAudioLevelsPollingTimer()
            }
        }
    }

    private var renderFacialRecognition: Bool {
        if let delegate = delegate {
            return delegate.cameraViewShouldRenderFacialRecognition(self)
        }
        return false
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        opaque = false
        backgroundColor = UIColor.clearColor()
    }

    private func configureAudioSession() {
        if let delegate = delegate {
            if delegate.cameraViewShouldEstablishAudioSession(self) {
                var input = AVCaptureDeviceInput.deviceInputWithDevice(mic, error: nil) as! AVCaptureInput
                captureSession.addInput(input)

                audioDataOutput = AVCaptureAudioDataOutput()
                if captureSession.canAddOutput(audioDataOutput) {
                    captureSession.addOutput(audioDataOutput)
                }
            }
        }
    }

    private func configureFacialRecognition() {
        if outputFaceMetadata {
            var metadataOutput = AVCaptureMetadataOutput()
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: avMetadataOutputQueue)
            metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes
        }

        if renderFacialRecognition {
            codeDetectionLayer = CALayer()
            codeDetectionLayer.frame = bounds
            layer.insertSublayer(codeDetectionLayer, above: capturePreviewLayer)
        }
    }

    private func configurePhotoSession() {
        stillCameraOutput = AVCaptureStillImageOutput()
        if captureSession.canAddOutput(stillCameraOutput) {
            captureSession.addOutput(stillCameraOutput)
        }
    }

    private func configureVideoSession() {
        if let delegate = delegate {
            if delegate.cameraViewShouldEstablishVideoSession(self) {
                videoDataOutput = AVCaptureVideoDataOutput()
                videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA]
                videoDataOutput.alwaysDiscardsLateVideoFrames = true
                videoDataOutput.setSampleBufferDelegate(self, queue: avVideoOutputQueue)

                videoFileOutput = AVCaptureMovieFileOutput()
            }
        }
    }

    private func startAudioLevelsPollingTimer() {
        audioLevelsPollingTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "pollForAudioLevels", userInfo: nil, repeats: true)
        audioLevelsPollingTimer.fire()
    }

    private func stopAudioLevelsPollingTimer() {
        if let timer = audioLevelsPollingTimer {
            timer.invalidate()
            audioLevelsPollingTimer = nil
        }
    }

    func pollForAudioLevels() {
        if audioDataOutput == nil {
            return
        }

        if audioDataOutput.connections.count > 0 {
            var connection = audioDataOutput.connections[0] as! AVCaptureConnection
            var channels = connection.audioChannels

            for channel in channels {
                let avg = channel.averagePowerLevel
                let peak = channel.peakHoldLevel

                delegate?.cameraView(self, didMeasureAveragePower: avg, peakHold: peak, forAudioChannel: channel as! AVCaptureAudioChannel)
            }
        }
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

        configureAudioSession()
        configureFacialRecognition()
        configurePhotoSession()
        configureVideoSession()

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

    func toggleCapture() {
        if let mode = delegate?.outputModeForCameraView(self) {
            switch mode {
            case .Audio:
                if recording == false {
                    // captureAudio()
                } else {
                    // audioFileOutput.stopRecording()
                }
                break
            case .Video:
                if recording == false {
                    captureVideo()
                } else {
                    videoFileOutput.stopRecording()
                }
                break
            case .VideoSampleBuffer:
                if recording == false {
                    captureVideo()
                } else {
                    captureSession.removeOutput(videoDataOutput)
                }
                break
            case .Selfie:
                captureFrame()
                break
            default:
                break
            }
        }
    }

    func captureFrame() {
        if isSimulator() {
            if let window = UIApplication.sharedApplication().keyWindow {
                UIGraphicsBeginImageContextWithOptions(window.bounds.size, false, UIScreen.mainScreen().scale)
                window.layer.renderInContext(UIGraphicsGetCurrentContext())
                var image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                self.delegate?.cameraView(self, didCaptureStillImage: image)
            }
            return
        }

        dispatch_async(avCameraOutputQueue) { () -> Void in
            if let cameraOutput = self.stillCameraOutput {
                let connection = cameraOutput.connectionWithMediaType(AVMediaTypeVideo)
                connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.currentDevice().orientation.rawValue)!

                self.stillCameraOutput.captureStillImageAsynchronouslyFromConnection(connection) { (imageDataSampleBuffer, error) -> Void in
                    if error == nil {
                        let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)

                        if let image = UIImage(data: imageData) {
                            let data = UIImageJPEGRepresentation(image, 1.0)
                            self.delegate?.cameraView(self, didCaptureStillImage: image)
                        }
                    } else {
                        logError("Error capturing still image \(error)")
                    }
                }
            }
        }
    }

    private func captureVideo() {
        if isSimulator() {
            return
        }

        if let mode = delegate?.outputModeForCameraView(self) {
            switch mode {
            case .Video:
                if captureSession.canAddOutput(videoFileOutput) {
                    captureSession.addOutput(videoFileOutput)
                }

                var paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
                var outputFileURL = NSURL(fileURLWithPath: "\(paths.first!)/\(NSDate().timeIntervalSince1970).m4v")
                videoFileOutput.startRecordingToOutputFileURL(outputFileURL, recordingDelegate: self)
                break
            case .VideoSampleBuffer:
                if captureSession.canAddOutput(videoDataOutput) {
                    captureSession.addOutput(videoDataOutput)
                }
                break
            default:
                break
            }
        }
    }

    // MARK: AVCaptureFileOutputRecordingDelegate

    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        recording = true

        delegate?.cameraView(self, didStartVideoCaptureAtURL: fileURL)
    }

    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        recording = false

        delegate?.cameraView(self, didFinishVideoCaptureAtURL: outputFileURL)
        captureSession.removeOutput(videoFileOutput)
    }

    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(captureOutput: AVCaptureOutput!, didDropSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        //println("dropped samples \(sampleBuffer)")
    }

    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        var imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        CVPixelBufferLockBaseAddress(imageBuffer, 0)

        var baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)

        var colorSpace = CGColorSpaceCreateDeviceRGB()
        var bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.PremultipliedFirst.rawValue)
        var context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, bitmapInfo)

        var quartzImage = CGBitmapContextCreateImage(context)
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0)
        
        let image = UIImage(CGImage: quartzImage)
    }

    // MARK: AVCaptureMetadataOutputObjectsDelegate

    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        for object in metadataObjects {
            if let metadataFaceObject = object as? AVMetadataFaceObject {
                let detectedFace = capturePreviewLayer.transformedMetadataObjectForMetadataObject(metadataFaceObject)
                delegate?.cameraView(self, didOutputMetadataFaceObject: detectedFace as! AVMetadataFaceObject)
            }
        }

        if renderFacialRecognition {
            dispatch_after_delay(0.0) {
                self.clearDetectedMetadataObjects()
                self.showDetectedMetadataObjects(metadataObjects)
            }
        }
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
                    shapeLayer.lineWidth = 1.0
                    shapeLayer.lineJoin = kCALineJoinRound
                    shapeLayer.path = UIBezierPath(rect: detectedCode.bounds).CGPath
                    codeDetectionLayer.addSublayer(shapeLayer)
                }
            }
        }
    }
}
