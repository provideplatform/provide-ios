//
//  ApplicationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit
import AVFoundation

protocol ApplicationViewControllerDelegate {
    func dismissApplicationViewController(viewController: ApplicationViewController)
}

class ApplicationViewController: ECSlidingViewController,
                                 MenuViewControllerDelegate,
                                 CameraViewControllerDelegate {

    var applicationViewControllerDelegate: ApplicationViewControllerDelegate!

    override func awakeFromNib() {
        super.awakeFromNib()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "currentUserLoggedOut", name: "ApplicationUserLoggedOut")

        topViewController = UIStoryboard("Application").instantiateInitialViewController()!
    }

    private var menuContainerView: MenuContainerView!

    override var navigationController: UINavigationController! {
        if let navigationController = topViewController as? UINavigationController {
            return navigationController
        }
        return super.navigationController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshCurrentUser()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        refreshMenu()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        teardownMenu()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func teardownMenu() {
        if let menuContainerView = menuContainerView {
            menuContainerView.closeMenu()
            menuContainerView.removeFromSuperview()
            self.menuContainerView = nil
        }
    }

    private func refreshMenu() {
        teardownMenu()

        dispatch_after_delay(0.0) {
            self.menuContainerView = MenuContainerView(frame: self.view.bounds)
            self.menuContainerView.setupMenuViewController(self)
        }
    }

    func refreshCurrentUser() {
        let user = currentUser()

        user.reload(
            { statusCode, mappingResult in
                self.refreshMenu()

                if currentUser().profileImageUrl == nil {
                    let authorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
                    if authorizationStatus == .Authorized {
                        self.initCameraViewController()
                    } else if authorizationStatus == .NotDetermined {
                        NSNotificationCenter.defaultCenter().postNotificationName("ApplicationWillRequestMediaAuthorization")
                        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo) { granted in
                            if granted {
                                self.initCameraViewController()
                            }
                        }
                    }
                }
            },
            onError: { error, statusCode, responseString in

            }
        )
    }

    func currentUserLoggedOut() {
        applicationViewControllerDelegate?.dismissApplicationViewController(self)
    }

    // MARK: MenuViewControllerDelegate

    func navigationControllerForMenuViewController(menuViewController: MenuViewController) -> UINavigationController! {
        return topViewController as! UINavigationController
    }

    // MARK: CameraViewControllerDelegate

    func outputModeForCameraViewController(viewController: CameraViewController) -> CameraOutputMode {
        return .Selfie
    }

    func cameraViewControllerDidBeginAsyncStillImageCapture(viewController: CameraViewController) {
        navigationController?.popViewControllerAnimated(false)
    }

    func cameraViewController(viewController: CameraViewController, didCaptureStillImage image: UIImage) {
        ApiService.sharedService().setUserDefaultProfileImage(image,
            onSuccess: { statusCode, mappingResult in

            },
            onError: { error, statusCode, responseString in

            }
        )
    }

    func cameraViewController(cameraViewController: CameraViewController, didStartVideoCaptureAtURL fileURL: NSURL) {

    }

    func cameraViewController(cameraViewController: CameraViewController, didFinishVideoCaptureAtURL fileURL: NSURL) {

    }

    func cameraViewController(viewController: CameraViewController, didSelectImageFromCameraRoll image: UIImage) {
        
    }

    func cameraViewControllerCanceled(viewController: CameraViewController) {
        dispatch_after_delay(0.0) {
            self.navigationController?.popViewControllerAnimated(false)
        }
    }

    func cameraViewControllerDidOutputFaceMetadata(viewController: CameraViewController, metadataFaceObject: AVMetadataFaceObject) {

    }

    func cameraViewControllerShouldOutputFaceMetadata(viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerShouldOutputOCRMetadata(viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerShouldRenderFacialRecognition(viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewController(viewController: CameraViewController, didRecognizeText text: String!) {
        
    }

    private func initCameraViewController() {
        let selfieViewController = UIStoryboard("Camera").instantiateViewControllerWithIdentifier("SelfieViewController") as! SelfieViewController
        selfieViewController.delegate = self

        navigationController?.pushViewController(selfieViewController, animated: false)
    }
}
