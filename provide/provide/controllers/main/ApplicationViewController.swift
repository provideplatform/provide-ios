//
//  ApplicationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import AVFoundation
import KTSwiftExtensions

protocol ApplicationViewControllerDelegate {
    func dismissApplicationViewController(_ viewController: ApplicationViewController)
}

class ApplicationViewController: UIViewController,
                                 MenuViewControllerDelegate,
                                 CameraViewControllerDelegate {

    var applicationViewControllerDelegate: ApplicationViewControllerDelegate!

    fileprivate var topViewController: UIViewController!

    fileprivate var menuContainerView: MenuContainerView!

    override func awakeFromNib() {
        super.awakeFromNib()

        NotificationCenter.default.addObserver(self, selector: #selector(ApplicationViewController.currentUserLoggedOut), name: "ApplicationUserLoggedOut")
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier! == "ApplicationUINavigationControllerEmbedSegue" {
            topViewController = segue.destination
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(
            alongsideTransition: { context in
                self.menuContainerView?.redraw(size)
            },
            completion: { (context) in

            }
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshCurrentUser()

        NotificationCenter.default.addObserverForName("ApplicationShouldShowInvalidCredentialsToast") { _ in
            self.showToast("The supplied credentials are invalid...", dismissAfter: 4.0)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        refreshMenu()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        teardownMenu()
    }

    func teardownMenu() {
        if let menuContainerView = menuContainerView {
            menuContainerView.closeMenu()
            menuContainerView.removeFromSuperview()
            self.menuContainerView = nil
        }
    }

    fileprivate func refreshMenu() {
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

                if currentUser().profileImageUrl == nil && !currentUser().hasBeenPromptedToTakeSelfie {
                    let authorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
                    if authorizationStatus == .authorized {
                        self.setHasBeenPromptedToTakeSelfieFlag()
                        self.initCameraViewController()
                    } else if authorizationStatus == .notDetermined {
                        NotificationCenter.default.postNotificationName("ApplicationWillRequestMediaAuthorization")
                        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { granted in
                            if granted {
                                self.setHasBeenPromptedToTakeSelfieFlag()
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

    func navigationControllerForMenuViewController(_ menuViewController: MenuViewController) -> UINavigationController! {
        return topViewController as! UINavigationController
    }

    // MARK: CameraViewControllerDelegate

    func outputModeForCameraViewController(_ viewController: CameraViewController) -> CameraOutputMode {
        return .selfie
    }

    func cameraViewControllerDidBeginAsyncStillImageCapture(_ viewController: CameraViewController) {
        let _ = navigationController?.popViewController(animated: false)
    }

    func cameraViewController(_ viewController: CameraViewController, didCaptureStillImage image: UIImage) {
        ApiService.sharedService().setUserDefaultProfileImage(image,
            onSuccess: { statusCode, mappingResult in

            },
            onError: { error, statusCode, responseString in

            }
        )
    }

    func cameraViewController(_ cameraViewController: CameraViewController, didStartVideoCaptureAtURL fileURL: URL) {

    }

    func cameraViewController(_ cameraViewController: CameraViewController, didFinishVideoCaptureAtURL fileURL: URL) {

    }

    func cameraViewController(_ viewController: CameraViewController, didSelectImageFromCameraRoll image: UIImage) {
        
    }

    func cameraViewControllerCanceled(_ viewController: CameraViewController) {
        dispatch_after_delay(0.0) {
            let _ = self.navigationController?.popViewController(animated: false)
        }
    }

    func cameraViewControllerDidOutputFaceMetadata(_ viewController: CameraViewController, metadataFaceObject: AVMetadataFaceObject) {

    }

    func cameraViewControllerShouldOutputFaceMetadata(_ viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerShouldOutputOCRMetadata(_ viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerShouldRenderFacialRecognition(_ viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewController(_ viewController: CameraViewController, didRecognizeText text: String!) {
        
    }

    fileprivate func initCameraViewController() {
        let selfieViewController = UIStoryboard("Camera").instantiateViewController(withIdentifier: "SelfieViewController") as! SelfieViewController
        selfieViewController.delegate = self

        dispatch_after_delay(0.0) {
            self.navigationController?.pushViewController(selfieViewController, animated: false)
        }
    }

    fileprivate func setHasBeenPromptedToTakeSelfieFlag() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey: "presentedSelfieViewController")
        userDefaults.synchronize()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
