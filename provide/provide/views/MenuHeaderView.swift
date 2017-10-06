//
//  MenuHeaderView.swift
//  provide
//
//  Created by Kyle Thomas on 7/27/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import AVFoundation

protocol MenuHeaderViewDelegate {
    func navigationViewControllerForMenuHeaderView(_ view: MenuHeaderView) -> UINavigationController!
}

class MenuHeaderView: UIView, UIActionSheetDelegate, CameraViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var delegate: MenuHeaderViewDelegate!

    @IBOutlet fileprivate weak var profileImageActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet fileprivate weak var profileImageView: UIImageView!
    @IBOutlet fileprivate weak var nameLabel: UILabel!
    @IBOutlet fileprivate weak var companyLabel: UILabel!
    @IBOutlet fileprivate weak var changeProfileImageButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()

        refresh()

        NotificationCenter.default.addObserverForName("ProfileImageShouldRefresh") { _ in
            if let user = currentUser {
                self.profileImageUrl = user.profileImageUrl as URL!
            } else {
                self.profileImageUrl = nil
            }
        }
    }

    var profileImageUrl: URL! {
        didSet {
            bringSubview(toFront: profileImageActivityIndicatorView)
            profileImageActivityIndicatorView.startAnimating()

            if let profileImageUrl = profileImageUrl {
                profileImageView.contentMode = .scaleAspectFit
                profileImageView.sd_setImage(with: profileImageUrl) { image, error, imageCacheType, url in
                    self.profileImageActivityIndicatorView.stopAnimating()

                    self.bringSubview(toFront: self.profileImageView)
                    self.profileImageView.makeCircular()
                    self.profileImageView.alpha = 1.0
                }
            } else {
                profileImageView.image = nil
                profileImageView.alpha = 0.0
            }
        }
    }

    func changeProfileImage() {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .alert : .actionSheet
        let alertController = UIAlertController(title: "Want to take a selfie or choose from your camera roll?", message: nil, preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        let selfieAction = UIAlertAction(title: "Selfie", style: .default) { action in
            self.initSelfieViewController()
        }

        let cameraRollAction = UIAlertAction(title: "Camera Roll", style: .default) { action in
            self.initImagePickerViewController()
        }
        alertController.addAction(selfieAction)
        alertController.addAction(cameraRollAction)

        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            navigationController.present(alertController, animated: true)
        }
    }

    fileprivate func refresh() {
        backgroundColor = .clear

        if let user = currentUser {
            profileImageUrl = user.profileImageUrl as URL!
            nameLabel.text = user.name
        } else {
            profileImageUrl = nil
            nameLabel.text = ""
        }

        companyLabel.text = ""

        changeProfileImageButton.addTarget(self, action: #selector(changeProfileImage), for: .touchUpInside)

        profileImageActivityIndicatorView.stopAnimating()
    }

    fileprivate func initImagePickerViewController() {
        let imagePickerViewController = ImagePickerViewController()
        imagePickerViewController.delegate = self

        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            NotificationCenter.default.postNotificationName("MenuContainerShouldReset")
            navigationController.present(imagePickerViewController, animated: true)
        }
    }

    // MARK: CameraViewControllerDelegate

    func outputModeForCameraViewController(_ viewController: CameraViewController) -> CameraOutputMode {
        return .selfie
    }

    func cameraViewControllerDidBeginAsyncStillImageCapture(_ viewController: CameraViewController) {
        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            NotificationCenter.default.postNotificationName("MenuContainerShouldOpen")
            navigationController.popViewController(animated: false)
        }
    }

    func cameraViewController(_ viewController: CameraViewController, didCaptureStillImage image: UIImage) {
        setUserDefaultProfileImage(image)
    }

    func cameraViewControllerCanceled(_ viewController: CameraViewController) {
        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            NotificationCenter.default.postNotificationName("MenuContainerShouldOpen")
            navigationController.popViewController(animated: false)
        }
    }

    func cameraViewControllerShouldOutputFaceMetadata(_ viewController: CameraViewController) -> Bool {
        return true
    }

    func cameraViewControllerShouldRenderFacialRecognition(_ viewController: CameraViewController) -> Bool {
        return true
    }

    func cameraViewControllerShouldOutputOCRMetadata(_ viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewController(_ viewController: CameraViewController, didSelectImageFromCameraRoll image: UIImage) {

    }

    func cameraViewController(_ cameraViewController: CameraViewController, didStartVideoCaptureAtURL fileURL: URL) {

    }

    func cameraViewController(_ cameraViewController: CameraViewController, didFinishVideoCaptureAtURL fileURL: URL) {

    }

    func cameraViewControllerDidOutputFaceMetadata(_ viewController: CameraViewController, metadataFaceObject: AVMetadataFaceObject) {

    }

    func cameraViewController(_ viewController: CameraViewController, didRecognizeText text: String!) {

    }

    fileprivate func initSelfieViewController() {
        let selfieViewController = UIStoryboard("Camera").instantiateViewController(withIdentifier: "SelfieViewController") as! SelfieViewController
        selfieViewController.delegate = self

        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            NotificationCenter.default.postNotificationName("MenuContainerShouldReset")
            navigationController.pushViewController(selfieViewController, animated: false)
        }
    }

    fileprivate func setUserDefaultProfileImage(_ image: UIImage) {
        profileImageView.image = nil
        profileImageView.alpha = 0.0
        profileImageUrl = nil

        ApiService.shared.setUserDefaultProfileImage(image, onSuccess: { response in

        }, onError: { urlResponse, statusCode, error in
            logError(error!)
        })
    }

    // MARK: UIImagePickerControllerDelegate

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [AnyHashable: Any]!) {
        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            navigationController.dismiss(animated: true) {
                NotificationCenter.default.postNotificationName("MenuContainerShouldOpen")
            }
        }

        setUserDefaultProfileImage(image)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            navigationController.dismiss(animated: true) {
                NotificationCenter.default.postNotificationName("MenuContainerShouldOpen")
            }
        }
    }

    // MARK: UINavigationControllerDelegate

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        //UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: false)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
