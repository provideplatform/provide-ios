//
//  MenuHeaderView.swift
//  provide
//
//  Created by Kyle Thomas on 7/27/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import AVFoundation

protocol MenuHeaderViewDelegate: class {
    func navigationViewControllerForMenuHeaderView(_ view: MenuHeaderView) -> UINavigationController?
}

class MenuHeaderView: UIView, UIActionSheetDelegate, CameraViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    weak var delegate: MenuHeaderViewDelegate?

    @IBOutlet private weak var profileImageActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var profileImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var companyLabel: UILabel!
    @IBOutlet private weak var changeProfileImageButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()

        refresh()

        KTNotificationCenter.addObserver(forName: .ProfileImageShouldRefresh) { _ in
            if let user = currentUser, let profileImageUrl = user.profileImageUrl {
                self.profileImageUrl = profileImageUrl
            } else {
                self.profileImageUrl = nil
            }
        }
    }

    private var profileImageUrl: URL? {
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

    @objc func changeProfileImage() {
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

    private func refresh() {
        backgroundColor = .clear

        if let user = currentUser {
            profileImageUrl = user.profileImageUrl
            nameLabel.text = user.name
        } else {
            profileImageUrl = nil
            nameLabel.text = ""
        }

        companyLabel.text = ""

        changeProfileImageButton.addTarget(self, action: #selector(changeProfileImage), for: .touchUpInside)

        profileImageActivityIndicatorView.stopAnimating()
    }

    private func initImagePickerViewController() {
        let imagePickerViewController = ImagePickerViewController()
        imagePickerViewController.delegate = self

        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            KTNotificationCenter.post(name: .MenuContainerShouldReset)
            navigationController.present(imagePickerViewController, animated: true)
        }
    }

    // MARK: CameraViewControllerDelegate

    func outputModeForCameraViewController(_ viewController: CameraViewController) -> CameraOutputMode {
        return .selfie
    }

    func cameraViewControllerDidBeginAsyncStillImageCapture(_ viewController: CameraViewController) {
        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            KTNotificationCenter.post(name: .MenuContainerShouldOpen)
            navigationController.popViewController(animated: false)
        }
    }

    func cameraViewController(_ viewController: CameraViewController, didCaptureStillImage image: UIImage) {
        setUserDefaultProfileImage(image)
    }

    func cameraViewControllerCanceled(_ viewController: CameraViewController) {
        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            KTNotificationCenter.post(name: .MenuContainerShouldOpen)
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

    private func initSelfieViewController() {
        let selfieViewController = UIStoryboard("Camera").instantiateViewController(withIdentifier: "SelfieViewController") as! SelfieViewController
        selfieViewController.delegate = self

        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            KTNotificationCenter.post(name: .MenuContainerShouldReset)
            navigationController.pushViewController(selfieViewController, animated: false)
        }
    }

    private func setUserDefaultProfileImage(_ image: UIImage) {
        profileImageView.image = nil
        profileImageView.alpha = 0.0
        profileImageUrl = nil

        ApiService.shared.setUserDefaultProfileImage(image,
            onSuccess: { response in
                logInfo("Updated default profile image")
            },
            onError: { urlResponse, statusCode, error in
                logError(error!)
            }
        )
    }

    // MARK: UIImagePickerControllerDelegate

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
                navigationController.dismiss(animated: false) {
                    KTNotificationCenter.post(name: .MenuContainerShouldOpen)
                }
            } else {
                picker.presentingViewController?.dismiss(animated: false) {
                    KTNotificationCenter.post(name: .MenuContainerShouldOpen)
                }
            }

            setUserDefaultProfileImage(image)
        } else {
            logWarn("UIImagePickerController selected invalid image media: \(info)")
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            navigationController.dismiss(animated: true) {
                KTNotificationCenter.post(name: .MenuContainerShouldOpen)
            }
        } else {
            picker.presentingViewController?.dismiss(animated: false) {
                KTNotificationCenter.post(name: .MenuContainerShouldOpen)
            }
        }
    }

    // MARK: UINavigationControllerDelegate

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        //UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: false)
    }
}
