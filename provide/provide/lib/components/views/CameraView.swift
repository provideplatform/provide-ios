//
//  CameraView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import AVFoundation

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

protocol CameraViewDelegate: class {
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

    weak var delegate: CameraViewDelegate?

    private let avAudioOutputQueue = DispatchQueue(label: "api.avAudioOutputQueue", attributes: [])
    private let avCameraOutputQueue = DispatchQueue(label: "api.avCameraOutputQueue", attributes: [])
    private let avMetadataOutputQueue = DispatchQueue(label: "api.avMetadataOutputQueue", attributes: [])
    private let avVideoOutputQueue = DispatchQueue(label: "api.avVideoOutputQueue", attributes: [])

    private var captureInput: AVCaptureInput!
    private var captureSession: AVCaptureSession!

    private var capturePreviewLayer: AVCaptureVideoPreviewLayer!
    private var codeDetectionLayer: CALayer!

    private var capturePreviewOrientation: AVCaptureVideoOrientation!

    private var audioDataOutput: AVCaptureAudioDataOutput!
    private var audioLevelsPollingTimer: Timer!

    private var videoDataOutput: AVCaptureVideoDataOutput!
    private var videoFileOutput: AVCaptureMovieFileOutput!

    private var stillCameraOutput: AVCaptureStillImageOutput!

    private var lastOCRTimestamp: Date!

    private var backCamera: AVCaptureDevice! {
        return AVCaptureDevice.devices(for: .video).first { ($0 as AnyObject).position == .back }
    }

    private var frontCamera: AVCaptureDevice! {
        return AVCaptureDevice.devices(for: .video).first { ($0 as AnyObject).position == .front }
    }

    var isRunning: Bool {
        return captureSession?.isRunning ?? false
    }

    private var mic: AVCaptureDevice! {
        return AVCaptureDevice.default(for: .audio)
    }

    private var outputFaceMetadata: Bool {
        return delegate?.cameraViewShouldOutputFaceMetadata(self) ?? false
    }

    private var outputOCRMetadata: Bool {
        return delegate?.cameraViewShouldOutputOCRMetadata(self) ?? false
    }

    private var recording = false {
        didSet {
            if recording {
                startAudioLevelsPollingTimer()
            } else {
                stopAudioLevelsPollingTimer()
            }
        }
    }

    private var renderFacialRecognition: Bool {
        return delegate?.cameraViewShouldRenderFacialRecognition(self) ?? false
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        isOpaque = false
        backgroundColor = .clear
    }

    private func configureAudioSession() {
        if let delegate = delegate, delegate.cameraViewShouldEstablishAudioSession(self) {
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

    private func configureFacialRecognition() {
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

    private func configurePhotoSession() {
        stillCameraOutput = AVCaptureStillImageOutput()
        if captureSession.canAddOutput(stillCameraOutput) {
            captureSession.addOutput(stillCameraOutput)
        }
    }

    private func configureVideoSession() {
        if let delegate = delegate, delegate.cameraViewShouldEstablishVideoSession(self) || outputOCRMetadata {
            videoDataOutput = AVCaptureVideoDataOutput()
            var settings = [AnyHashable: Any]()
            settings.updateValue(NSNumber(value: kCVPixelFormatType_32BGRA as UInt32), forKey: String(kCVPixelBufferPixelFormatTypeKey))
            videoDataOutput.videoSettings = settings as! [String: Any]
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.setSampleBufferDelegate(self, queue: avVideoOutputQueue)

            captureSession.addOutput(videoDataOutput)

            videoFileOutput = AVCaptureMovieFileOutput()
        }
    }

    private func startAudioLevelsPollingTimer() {
        audioLevelsPollingTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(pollForAudioLevels), userInfo: nil, repeats: true)
        audioLevelsPollingTimer.fire()
    }

    private func stopAudioLevelsPollingTimer() {
        if let timer = audioLevelsPollingTimer {
            timer.invalidate()
            audioLevelsPollingTimer = nil
        }
    }

    func setCapturePreviewOrientationWithDeviceOrientation(_ deviceOrientation: UIDeviceOrientation, size: CGSize) {
        if  let capturePreviewLayer = capturePreviewLayer {
            capturePreviewLayer.frame.size = size

            if let connection = capturePreviewLayer.connection {
                switch deviceOrientation {
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

    @objc func pollForAudioLevels() {
        if audioDataOutput == nil {
            return
        }

        if audioDataOutput.connections.count > 0 {
            let connection = audioDataOutput.connections[0]
            let channels = connection.audioChannels

            for channel in channels {
                let avg = (channel as AnyObject).averagePowerLevel
                let peak = (channel as AnyObject).peakHoldLevel

                delegate?.cameraView(self, didMeasureAveragePower: avg!, peakHold: peak!, forAudioChannel: channel )
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

        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
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
            captureSession.sessionPreset = .high
            captureSession.addInput(input)

            capturePreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            capturePreviewLayer.frame = bounds
            capturePreviewLayer.videoGravity = .resizeAspectFill
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

        if capturePreviewLayer != nil {
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
            case .photo:
                captureFrame()
            case .selfie:
                captureFrame()
            case .video:
                if recording == false {
                    captureVideo()
                } else {
                    videoFileOutput.stopRecording()
                }
            case .videoSampleBuffer:
                if recording == false {
                    captureVideo()
                } else {
                    captureSession.removeOutput(videoDataOutput)
                }
            }
        }
    }

    private func captureFrame() {
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
            if let cameraOutput = self.stillCameraOutput, let connection = cameraOutput.connection(with: .video) {
                if let videoOrientation = AVCaptureVideoOrientation(rawValue: UIDevice.current.orientation.rawValue) {
                    connection.videoOrientation = videoOrientation
                }

                let delegate = self.delegate  // HACK -- this keeps a reference to the delegate around... holistic audit of all optionality refactoring required ASAP
                                              // weak var delegeate is no longer behaving the way it once did...

                cameraOutput.captureStillImageAsynchronously(from: connection) { [weak self] imageDataSampleBuffer, error in
                    if error == nil {
                        let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer!)

                        if let image = UIImage(data: imageData!) {
                            delegate?.cameraView(self!, didCaptureStillImage: image)

                            if self?.outputOCRMetadata ?? false {
                                self?.ocrFrame(image)
                            }
                        }
                    } else {
                        logWarn("Error capturing still image \(String(describing: error))")
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
            case .video:
                if captureSession.canAddOutput(videoFileOutput) {
                    captureSession.addOutput(videoFileOutput)
                }

                let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                let outputFileURL = URL(fileURLWithPath: "\(paths.first!)/\(Date().timeIntervalSince1970).m4v")
                videoFileOutput.startRecording(to: outputFileURL, recordingDelegate: self)
            case .videoSampleBuffer:
                if captureSession.canAddOutput(videoDataOutput) {
                    captureSession.addOutput(videoDataOutput)
                }
            default:
                break
            }
        }
    }

    // MARK: AVCaptureFileOutputRecordingDelegate

    func fileOutput(_ captureOutput: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        recording = true

        delegate?.cameraView(self, didStartVideoCaptureAtURL: fileURL)
    }

    func fileOutput(_ captureOutput: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        recording = false

        delegate?.cameraView(self, didFinishVideoCaptureAtURL: outputFileURL)
        captureSession.removeOutput(videoFileOutput)
    }

    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(_ captureOutput: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //println("dropped samples \(sampleBuffer)")
    }

    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
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

    func metadataOutput(captureOutput: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        for object in metadataObjects {
            if let metadataFaceObject = object as? AVMetadataFaceObject {
                let detectedFace = capturePreviewLayer.transformedMetadataObject(for: metadataFaceObject)
                delegate?.cameraView(self, didOutputMetadataFaceObject: detectedFace as! AVMetadataFaceObject)
            }
        }

        if renderFacialRecognition {
            DispatchQueue.main.async {
                self.clearDetectedMetadataObjects()
                self.showDetectedMetadataObjects(metadataObjects as [Any]!)
            }
        }
    }

    private func clearDetectedMetadataObjects() {
        if let codeDetectionLayer = codeDetectionLayer {
            codeDetectionLayer.sublayers = nil
        }
    }

    private func showDetectedMetadataObjects(_ metadataObjects: [Any]!) {
        for object in metadataObjects {
            if let metadataFaceObject = object as? AVMetadataFaceObject, let detectedCode = capturePreviewLayer.transformedMetadataObject(for: metadataFaceObject) as? AVMetadataFaceObject {
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

    private func ocrFrame(_ frame: UIImage) {
        if let lastOCRTimestamp = lastOCRTimestamp {
            if abs(lastOCRTimestamp.timeIntervalSinceNow) >= 2.0 {
                dispatch_async_global_queue {
                    self.lastOCRTimestamp = NSDate() as Date!

                    // let tesseract = G8Tesseract(language: "eng")
                    // tesseract.delegate = self
                    //
                    // //            tesseract = G8Tesseract(language: "eng")
                    // //            tesseract.delegate = self
                    // //
                    // //            // Optionaly: You could specify engine to recognize with.
                    // //            // G8OCREngineModeTesseractOnly by default. It provides more features and faster
                    // //            // than Cube engine. See G8Constants.h for more information.
                    // //            //tesseract.engineMode = G8OCREngineModeTesseractOnly;
                    // //
                    // //            // This is wrapper for common Tesseract variable kG8ParamTesseditCharWhitelist:
                    // //            // [tesseract setVariableValue:@"0123456789" forKey:kG8ParamTesseditCharBlacklist];
                    // //            // See G8TesseractParameters.h for a complete list of Tesseract variables
                    // //
                    // //            // Optional: Limit the character set Tesseract should not try to recognize from
                    // //            //tesseract.charBlacklist = @"OoZzBbSs";
                    //
                    // tesseract.image = frame
                    //
                    // // TODO: find receipt rect and use -- tesseract.rect = CGRectMake(20, 20, 100, 100)
                    //
                    // tesseract.maximumRecognitionTime = 2.0
                    // tesseract.recognize()

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
