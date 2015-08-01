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
                                 UINavigationControllerDelegate,
                                 MenuViewControllerDelegate,
                                 CameraViewControllerDelegate {

    var applicationViewControllerDelegate: ApplicationViewControllerDelegate!

    override func awakeFromNib() {
        super.awakeFromNib()

        topViewController = UIStoryboard("Application").instantiateInitialViewController() as! UIViewController
        (topViewController as! UINavigationController).delegate = self
    }

    private var menuContainerView: MenuContainerView!
    private var menuViewController: MenuViewController!

    override var navigationController: UINavigationController! {
        if let navigationController = topViewController as? UINavigationController {
            return navigationController
        }
        return super.navigationController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshMenu()
        refreshCurrentUser()
    }

    private func refreshMenu() {
        if let menuContainerView = menuContainerView {
            menuContainerView.closeMenu()
            menuContainerView.removeFromSuperview()
            self.menuContainerView = nil
        }

        menuContainerView = MenuContainerView(frame: view.bounds)
        menuContainerView.setupMenuViewController(self)
    }

    func refreshCurrentUser() {
        let user = currentUser()
        assert(user.id != nil)

        user.reload(
            { statusCode, mappingResult in
                self.refreshMenu()

                if currentUser().profileImageUrl == nil {
                    self.initCameraViewController()
                }
            },
            onError: { error, statusCode, responseString in

            }
        )
    }

    func currentUserLoggedOut() {
        applicationViewControllerDelegate?.dismissApplicationViewController(self)
    }

    // MARK: UINavigationControllerDelegate

    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        if viewController.isKindOfClass(TopViewController) {
            applicationViewControllerDelegate?.dismissApplicationViewController(self)
        }
    }

    // MARK: MenuViewControllerDelegate

    func navigationControllerForMenuViewController(menuViewController: MenuViewController) -> UINavigationController! {
        return topViewController as! UINavigationController
    }

    // MARK: CameraViewControllerDelegate

    func outputModeForCameraViewController(viewController: CameraViewController) -> CameraOutputMode {
        return .Selfie
    }

    func cameraViewController(viewController: CameraViewController, didCaptureStillImage image: UIImage) {
        navigationController?.popViewControllerAnimated(false)

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
        navigationController?.popViewControllerAnimated(false)
    }

    func cameraViewControllerDidOutputFaceMetadata(viewController: CameraViewController, metadataFaceObject: AVMetadataFaceObject) {

    }

    func cameraViewControllerShouldOutputFaceMetadata(viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerShouldRenderFacialRecognition(viewController: CameraViewController) -> Bool {
        return false
    }

    private func initCameraViewController() {
        let selfieViewController = UIStoryboard("Camera").instantiateViewControllerWithIdentifier("SelfieViewController") as! SelfieViewController
        selfieViewController.delegate = self

        navigationController?.pushViewController(selfieViewController, animated: false)
    }
}
