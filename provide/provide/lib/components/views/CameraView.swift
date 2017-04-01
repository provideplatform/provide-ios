 //
//  CameraView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import AVFoundation
import KTSwiftExtensions

enum ActiveDeviceCapturePosition {
    case back, front
}

enum CameraOutputMode {
    case audio
    case video
    case videoSampleBuffer
    case photo
    case selfie
}

protocol CameraViewDelegate {
    func outputModeForCameraView(_ cameraView: CameraView) -> CameraOutputMode
    func cameraView(_ cameraView: CameraView, didCaptureStillImage image: UIImage)
    func cameraView(_ cameraView: CameraView, didStartVideoCaptureAtURL fileURL: URL)
    func cameraView(_ cameraView: CameraView, didFinishVideoCaptureAtURL fileURL: URL)
    func cameraView(_ cameraView: CameraView, didMeasureAveragePower avgPower: Float, peakHold: Float, forAudioChannel channel: AVCaptureAudioChannel)
    func cameraView(_ cameraView: CameraView, didOutputMetadataFaceObject metadataFaceObject: AVMetadataFaceObject)
    func cameraView(_ cameraView: CameraView, didRecognizeText text: String!)

    func cameraViewCaptureSessionFailedToInitializeWithError(_ error: NSError)
    func cameraViewBeganAsyncStillImageCapture(_ cameraView: CameraView)
    func cameraViewShouldEstablishAudioSession(_ cameraView: CameraView) -> Bool
    func cameraViewShouldEstablishVideoSession(_ cameraView: CameraView) -> Bool
    func cameraViewShouldOutputFaceMetadata(_ cameraView: CameraView) -> Bool
    func cameraViewShouldOutputOCRMetadata(_ cameraView: CameraView) -> Bool
    func cameraViewShouldRenderFacialRecognition(_ cameraView: CameraView) -> Bool
}

class CameraView: UIView, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate, AVCaptureMetadataOutputObjectsDelegate {

    var delegate: CameraViewDelegate!

    fileprivate let avAudioOutputQueue = DispatchQueue(label: "api.avAudioOutputQueue", attributes: [])
    fileprivate let avCameraOutputQueue = DispatchQueue(label: "api.avCameraOutputQueue", attributes: [])
    fileprivate let avMetadataOutputQueue = DispatchQueue(label: "api.avMetadataOutputQueue", attributes: [])
    fileprivate let avVideoOutputQueue = DispatchQueue(label: "api.avVideoOutputQueue", attributes: [])

    fileprivate var captureInput: AVCaptureInput!
    fileprivate var captureSession: AVCaptureSession!

    fileprivate var capturePreviewLayer: AVCaptureVideoPreviewLayer!
    fileprivate var codeDetectionLayer: CALayer!

    fileprivate var capturePreviewOrientation: AVCaptureVideoOrientation!

    fileprivate var audioDataOutput: AVCaptureAudioDataOutput!
    fileprivate var audioLevelsPollingTimer: Timer!

    fileprivate var videoDataOutput: AVCaptureVideoDataOutput!
    fileprivate var videoFileOutput: AVCaptureMovieFileOutput!

    fileprivate var stillCameraOutput: AVCaptureStillImageOutput!

    fileprivate var lastOCRTimestamp: Date!

    fileprivate var backCamera: AVCaptureDevice! {
        for device in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) {
            if (device as AnyObject).position == .back {
                return device as! AVCaptureDevice
            }
        }
        return nil
    }

    fileprivate var frontCamera: AVCaptureDevice! {
        for device in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) {
            if (device as AnyObject).position == .front {
                return device as? AVCaptureDevice
            }
        }
        return nil
    }

    var isRunning: Bool {
        if let captureSession = captureSession {
            return captureSession.isRunning
        }
        return false
    }

    fileprivate var mic: AVCaptureDevice! {
        get {
            return AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        }
    }

    fileprivate var outputFaceMetadata: Bool {
        if let delegate = delegate {
            return delegate.cameraViewShouldOutputFaceMetadata(self)
        }
        return false
    }

    fileprivate var outputOCRMetadata: Bool {
        if let delegate = delegate {
            return delegate.cameraViewShouldOutputOCRMetadata(self)
        }
        return false
    }

    fileprivate var recording = false {
        didSet {
            if recording == true {
                startAudioLevelsPollingTimer()
            } else {
                stopAudioLevelsPollingTimer()
            }
        }
    }

    fileprivate var renderFacialRecognition: Bool {
        if let delegate = delegate {
            return delegate.cameraViewShouldRenderFacialRecognition(self)
        }
        return false
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        isOpaque = false
        backgroundColor = UIColor.clear
    }

    fileprivate func configureAudioSession() {
        if let delegate = delegate {
            if delegate.cameraViewShouldEstablishAudioSession(self) {
                do {
                    let input = try AVCaptureDeviceInput(device: mic)
                    captureSession.addInput(input)

                    audioDataOutput = AVCaptureAudioDataOutput()
                    if captureSession.canAddOutput(audioDataOutput) {
                        captureSession.addOutput(audioDataOutput)
                    }
                } catch let error as NSError {
                    logWarn(error.localizedDescription)
                }
            }
        }
    }

    fileprivate func configureFacialRecognition() {
        if outputFaceMetadata {
            let metadataOutput = AVCaptureMetadataOutput()
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

    fileprivate func configurePhotoSession() {
        stillCameraOutput = AVCaptureStillImageOutput()
        if captureSession.canAddOutput(stillCameraOutput) {
            captureSession.addOutput(stillCameraOutput)
        }
    }

    fileprivate func configureVideoSession() {
        if let delegate = delegate {
            if delegate.cameraViewShouldEstablishVideoSession(self) || outputOCRMetadata {
                videoDataOutput = AVCaptureVideoDataOutput()
                var settings = [AnyHashable: Any]()
                settings.updateValue(NSNumber(value: kCVPixelFormatType_32BGRA as UInt32), forKey: String(kCVPixelBufferPixelFormatTypeKey))
                videoDataOutput.videoSettings = settings
                videoDataOutput.alwaysDiscardsLateVideoFrames = true
                videoDataOutput.setSampleBufferDelegate(self, queue: avVideoOutputQueue)

                captureSession.addOutput(videoDataOutput)

                videoFileOutput = AVCaptureMovieFileOutput()
            }
        }
    }

    fileprivate func startAudioLevelsPollingTimer() {
        audioLevelsPollingTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(CameraView.pollForAudioLevels), userInfo: nil, repeats: true)
        audioLevelsPollingTimer.fire()
    }

    fileprivate func stopAudioLevelsPollingTimer() {
        if let timer = audioLevelsPollingTimer {
            timer.invalidate()
            audioLevelsPollingTimer = nil
        }
    }

    func setCapturePreviewOrientationWithDeviceOrientation(_ deviceOrientation: UIDeviceOrientation, size: CGSize) {
        if  let capturePreviewLayer = capturePreviewLayer {
            capturePreviewLayer.frame.size = size
            
            if let connection = capturePreviewLayer.connection {
                switch (deviceOrientation) {
                case .portrait:
                    connection.videoOrientation = .portrait
                case .landscapeRight:
                    connection.videoOrientation = .landscapeLeft
                case .landscapeLeft:
                    connection.videoOrientation = .landscapeRight
                default:
                    connection.videoOrientation = .portrait
                }
            }
        }
    }

    func pollForAudioLevels() {
        if audioDataOutput == nil {
            return
        }

        if audioDataOutput.connections.count > 0 {
            let connection = audioDataOutput.connections[0] as! AVCaptureConnection
            let channels = connection.audioChannels

            for channel in channels! {
                let avg = (channel as AnyObject).averagePowerLevel
                let peak = (channel as AnyObject).peakHoldLevel

                delegate?.cameraView(self, didMeasureAveragePower: avg!, peakHold: peak!, forAudioChannel: channel as! AVCaptureAudioChannel)
            }
        }
    }

    func startBackCameraCapture() {
        if let backCamera = backCamera {
            startCapture(backCamera)
        }
    }

    func startFrontCameraCapture() {
        if let frontCamera = frontCamera {
            startCapture(frontCamera)
        }
    }

    func startCapture(_ device: AVCaptureDevice) {
        if captureSession != nil {
            stopCapture()
        }

        if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) == .notDetermined {
            NotificationCenter.default.postNotificationName("ApplicationWillRequestMediaAuthorization")
        }

        do {
            try device.lockForConfiguration()

            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            } else if device.isFocusModeSupported(.autoFocus) {
                device.focusMode = .autoFocus
            }

            device.unlockForConfiguration()
        } catch let error as NSError {
            logWarn(error.localizedDescription)
            delegate?.cameraViewCaptureSessionFailedToInitializeWithError(error)
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)

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
        } catch let error as NSError {
            logWarn(error.localizedDescription)
            delegate?.cameraViewCaptureSessionFailedToInitializeWithError(error)
        }
    }

    func stopCapture() {
        if let session = captureSession {
            session.stopRunning()
            captureSession = nil
        }

        if let _ = capturePreviewLayer {
            capturePreviewLayer.removeFromSuperlayer()
            capturePreviewLayer = nil
        }
    }

    func capture() {
        if let mode = delegate?.outputModeForCameraView(self) {
            switch mode {
            case .audio:
                if recording == false {
                    // captureAudio()
                } else {
                    // audioFileOutput.stopRecording()
                }
                break
            case .photo:
                captureFrame()
                break
            case .selfie:
                captureFrame()
                break
            case .video:
                if recording == false {
                    captureVideo()
                } else {
                    videoFileOutput.stopRecording()
                }
                break
            case .videoSampleBuffer:
                if recording == false {
                    captureVideo()
                } else {
                    captureSession.removeOutput(videoDataOutput)
                }
                break
            }
        }
    }

    fileprivate func captureFrame() {
        delegate?.cameraViewBeganAsyncStillImageCapture(self)

        if isSimulator() {
            if let window = UIApplication.shared.keyWindow {
                UIGraphicsBeginImageContextWithOptions(window.bounds.size, false, UIScreen.main.scale)
                window.layer.render(in: UIGraphicsGetCurrentContext()!)
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                delegate?.cameraView(self, didCaptureStillImage: image!)
            }
            return
        }

        avCameraOutputQueue.async {
            if let cameraOutput = self.stillCameraOutput {
                if let connection = cameraOutput.connection(withMediaType: AVMediaTypeVideo) {
                    if let videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue) {
                        connection.videoOrientation = videoOrientation
                    }

                    cameraOutput.captureStillImageAsynchronously(from: connection) { imageDataSampleBuffer, error in
                        if error == nil {
                            let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer)

                            if let image = UIImage(data: imageData!) {
                                self.delegate?.cameraView(self, didCaptureStillImage: image)

                                if self.outputOCRMetadata {
                                    self.ocrFrame(image)
                                }
                            }
                        } else {
                            logWarn("Error capturing still image \(String(describing: error))")
                        }
                    }
                }
            }
        }
    }

    fileprivate func captureVideo() {
        if isSimulator() {
            return
        }

        if let mode = delegate?.outputModeForCameraView(self) {
            switch mode {
            case .video:
                if captureSession.canAddOutput(videoFileOutput) {
                    captureSession.addOutput(videoFileOutput)
                }

                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let outputFileURL = URL(fileURLWithPath: "\(paths.first!)/\(Date().timeIntervalSince1970).m4v")
                videoFileOutput.startRecording(toOutputFileURL: outputFileURL, recordingDelegate: self)
                break
            case .videoSampleBuffer:
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

    func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
        recording = true

        delegate?.cameraView(self, didStartVideoCaptureAtURL: fileURL)
    }

    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        recording = false

        delegate?.cameraView(self, didFinishVideoCaptureAtURL: outputFileURL)
        captureSession.removeOutput(videoFileOutput)
    }

    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        //println("dropped samples \(sampleBuffer)")
    }

    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))

        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue).rawValue
        let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)

        let quartzImage = context?.makeImage()!
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: CVOptionFlags(0)))
        
        let frame = UIImage(cgImage: quartzImage!)

        if outputOCRMetadata {
            ocrFrame(frame)
        }
    }

    // MARK: AVCaptureMetadataOutputObjectsDelegate

    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        for object in metadataObjects {
            if let metadataFaceObject = object as? AVMetadataFaceObject {
                let detectedFace = capturePreviewLayer.transformedMetadataObject(for: metadataFaceObject)
                delegate?.cameraView(self, didOutputMetadataFaceObject: detectedFace as! AVMetadataFaceObject)
            }
        }

        if renderFacialRecognition {
            dispatch_after_delay(0.0) {
                self.clearDetectedMetadataObjects()
                self.showDetectedMetadataObjects(metadataObjects as [AnyObject]!)
            }
        }
    }

    fileprivate func clearDetectedMetadataObjects() {
        if let codeDetectionLayer = codeDetectionLayer {
            codeDetectionLayer.sublayers = nil
        }
    }

    fileprivate func showDetectedMetadataObjects(_ metadataObjects: [AnyObject]!) {
        for object in metadataObjects {
            if let metadataFaceObject = object as? AVMetadataFaceObject {
                if let detectedCode = capturePreviewLayer.transformedMetadataObject(for: metadataFaceObject) as? AVMetadataFaceObject {
                    let shapeLayer = CAShapeLayer()
                    shapeLayer.strokeColor = UIColor.green.cgColor
                    shapeLayer.fillColor = UIColor.clear.cgColor
                    shapeLayer.lineWidth = 1.0
                    shapeLayer.lineJoin = kCALineJoinRound
                    shapeLayer.path = UIBezierPath(rect: detectedCode.bounds).cgPath
                    codeDetectionLayer.addSublayer(shapeLayer)
                }
            }
        }
    }

    fileprivate func ocrFrame(_ frame: UIImage) {
        if let lastOCRTimestamp = lastOCRTimestamp {
            if abs(lastOCRTimestamp.timeIntervalSinceNow) >= 2.0 {
                dispatch_async_global_queue {
                    self.lastOCRTimestamp = NSDate() as Date!

//                    let tesseract = G8Tesseract(language: "eng")
//                    tesseract.delegate = self
//
//                    //            tesseract = G8Tesseract(language: "eng")
//                    //            tesseract.delegate = self
//                    //
//                    //            // Optionaly: You could specify engine to recognize with.
//                    //            // G8OCREngineModeTesseractOnly by default. It provides more features and faster
//                    //            // than Cube engine. See G8Constants.h for more information.
//                    //            //tesseract.engineMode = G8OCREngineModeTesseractOnly;
//                    //
//                    //            // This is wrapper for common Tesseract variable kG8ParamTesseditCharWhitelist:
//                    //            // [tesseract setVariableValue:@"0123456789" forKey:kG8ParamTesseditCharBlacklist];
//                    //            // See G8TesseractParameters.h for a complete list of Tesseract variables
//                    //
//                    //            // Optional: Limit the character set Tesseract should not try to recognize from
//                    //            //tesseract.charBlacklist = @"OoZzBbSs";
//
//                    tesseract.image = frame
//
//                    // TODO: find receipt rect and use -- tesseract.rect = CGRectMake(20, 20, 100, 100)
//
//                    tesseract.maximumRecognitionTime = 2.0
//                    tesseract.recognize()

                    if self.outputOCRMetadata {
                        //self.delegate?.cameraView(self, didRecognizeText: tesseract.recognizedText)
                    }
                }
            }
        } else {
            lastOCRTimestamp = Date()
        }
    }
}
