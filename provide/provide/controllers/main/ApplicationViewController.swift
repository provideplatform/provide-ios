//
//  ApplicationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import AVFoundation

protocol ApplicationViewControllerDelegate: class {
    func dismissApplicationViewController(_ viewController: ApplicationViewController)
}

class ApplicationViewController: UIViewController, CameraViewControllerDelegate {

    weak var applicationViewControllerDelegate: ApplicationViewControllerDelegate?

    private var topViewController: UIViewController!

    private var menuContainerView: MenuContainerView!

    override func awakeFromNib() {
        super.awakeFromNib()

        KTNotificationCenter.addObserver(observer: self, selector: #selector(currentUserLoggedOut), name: .ApplicationUserLoggedOut)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier! == "ApplicationUINavigationControllerEmbedSegue" {
            topViewController = segue.destination
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { context in
            self.menuContainerView?.redraw(size)
        })
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshCurrentUser()

        KTNotificationCenter.addObserver(forName: .ApplicationShouldShowInvalidCredentialsToast) { _ in
            self.showToast("The supplied credentials are invalid...", dismissAfter: 4.0)
        }

        KTNotificationCenter.addObserver(forName: .ApplicationShouldReloadTopViewController) { [weak self] _ in
            if let tnc = self?.topViewController as? UINavigationController, let tvc = tnc.viewControllers.first as? TopViewController {
                tvc.reload()
            }

            dispatch_after_delay(0.025) {
                self?.refreshMenu()
                self?.requireMinimumViableUser()
            }
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

    private func teardownMenu() {
        if let menuContainerView = menuContainerView {
            menuContainerView.closeMenu()
            menuContainerView.removeFromSuperview()
            self.menuContainerView = nil
        }
    }

    private func refreshMenu() {
        teardownMenu()

        DispatchQueue.main.async {
            self.menuContainerView = MenuContainerView(frame: self.view.bounds)

            if let tnc = self.topViewController as? UINavigationController, tnc.viewControllers.first is MenuViewControllerDelegate {
                self.menuContainerView.setupMenuViewController(tnc.viewControllers.first as! MenuViewControllerDelegate)
            }
        }
    }

    private func refreshCurrentUser() {
        if let user = KeyChainService.shared.token?.user, currentUser == nil {
            currentUser = user
        }

        ApiService.shared.fetchCurrentUser(onSuccess: { _, _ in
            currentUser.reloadPaymentMethods(onSuccess: { [weak self] _, _ in
                self?.requireMinimumViableUser()
            }, onError: { error, statusCode, responseString in
                logError(error)
            })
        }, onError: { error, statusCode, responseString in
            logError(error)
        })
    }

    private func requireMinimumViableUser() {
        func promptUserToTakeSelfie() {
            let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            switch authorizationStatus {
            case .authorized:
                self.setHasBeenPromptedToTakeSelfieFlag()
                self.initCameraViewController()
            case .notDetermined:
                KTNotificationCenter.post(name: .ApplicationWillRequestMediaAuthorization)
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted {
                        self.setHasBeenPromptedToTakeSelfieFlag()
                        self.initCameraViewController()
                    }
                }
            case .restricted, .denied:
                break
            }
        }

        if currentUser.defaultPaymentMethod == nil {
            KTNotificationCenter.post(name: Notification.Name(rawValue: "SegueToPaymentsStoryboard"), object: nil)
        } else if currentUser.profileImageUrl == nil && !currentUser.hasBeenPromptedToTakeSelfie {
            promptUserToTakeSelfie()
        }
    }

    @objc func currentUserLoggedOut() {
        applicationViewControllerDelegate?.dismissApplicationViewController(self)
    }

    // MARK: CameraViewControllerDelegate

    func outputModeForCameraViewController(_ viewController: CameraViewController) -> CameraOutputMode {
        return .selfie
    }

    func cameraViewControllerDidBeginAsyncStillImageCapture(_ viewController: CameraViewController) {
        _ = navigationController?.popViewController(animated: false)
    }

    func cameraViewController(_ viewController: CameraViewController, didCaptureStillImage image: UIImage) {
        ApiService.shared.setUserDefaultProfileImage(image, onSuccess: { response in

        }, onError: { urlResponse, statusCode, error in
            logError(error!)
        })
    }

    func cameraViewController(_ cameraViewController: CameraViewController, didStartVideoCaptureAtURL fileURL: URL) {

    }

    func cameraViewController(_ cameraViewController: CameraViewController, didFinishVideoCaptureAtURL fileURL: URL) {

    }

    func cameraViewController(_ viewController: CameraViewController, didSelectImageFromCameraRoll image: UIImage) {

    }

    func cameraViewControllerCanceled(_ viewController: CameraViewController) {
        DispatchQueue.main.async {
            _ = self.navigationController?.popViewController(animated: false)
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

    private func initCameraViewController() {
        let selfieViewController = UIStoryboard("Camera").instantiateViewController(withIdentifier: "SelfieViewController") as! SelfieViewController
        selfieViewController.delegate = self

        DispatchQueue.main.async {
            self.navigationController?.pushViewController(selfieViewController, animated: false)
        }
    }

    private func setHasBeenPromptedToTakeSelfieFlag() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey: "presentedSelfieViewController")
        userDefaults.synchronize()
    }
}
