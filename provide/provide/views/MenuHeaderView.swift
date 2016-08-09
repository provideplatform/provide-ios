//
//  MenuHeaderView.swift
//  provide
//
//  Created by Kyle Thomas on 7/27/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit
import AVFoundation
import KTSwiftExtensions

protocol MenuHeaderViewDelegate {
    func navigationViewControllerForMenuHeaderView(view: MenuHeaderView) -> UINavigationController!
}

class MenuHeaderView: UIView, UIActionSheetDelegate, CameraViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    var delegate: MenuHeaderViewDelegate!

    @IBOutlet private weak var profileImageActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var profileImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var companyLabel: UILabel!
    @IBOutlet private weak var changeProfileImageButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = UIColor.clearColor()

        profileImageUrl = currentUser().profileImageUrl
        nameLabel.text = currentUser().name
        companyLabel.text = ""

        changeProfileImageButton.addTarget(self, action: #selector(MenuHeaderView.changeProfileImage), forControlEvents: .TouchUpInside)

        profileImageActivityIndicatorView.stopAnimating()

        NSNotificationCenter.defaultCenter().addObserverForName("ProfileImageShouldRefresh") { _ in
            self.profileImageUrl = currentUser().profileImageUrl
        }
    }

    var profileImageUrl: NSURL! {
        didSet {
            bringSubviewToFront(profileImageActivityIndicatorView)
            profileImageActivityIndicatorView.startAnimating()

            if let profileImageUrl = profileImageUrl {
                profileImageView.contentMode = .ScaleAspectFit
                profileImageView.sd_setImageWithURL(profileImageUrl) { image, error, imageCacheType, url in
                    self.profileImageActivityIndicatorView.stopAnimating()

                    self.bringSubviewToFront(self.profileImageView)
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
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .Alert : .ActionSheet
        let alertController = UIAlertController(title: "Want to take a selfie or choose from your camera roll?", message: nil, preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)


        let selfieAction = UIAlertAction(title: "Selfie", style: .Default) { action in
            self.initSelfieViewController()
        }

        let cameraRollAction = UIAlertAction(title: "Camera Roll", style: .Default) { action in
            self.initImagePickerViewController()
        }
        alertController.addAction(selfieAction)
        alertController.addAction(cameraRollAction)

        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            navigationController.presentViewController(alertController, animated: true)
        }
    }

    private func initImagePickerViewController() {
        let imagePickerViewController = ImagePickerViewController()
        imagePickerViewController.delegate = self

        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            NSNotificationCenter.defaultCenter().postNotificationName("MenuContainerShouldReset")
            navigationController.presentViewController(imagePickerViewController, animated: true)
        }
    }

    // MARK: CameraViewControllerDelegate

    func outputModeForCameraViewController(viewController: CameraViewController) -> CameraOutputMode {
        return .Selfie
    }

    func cameraViewControllerDidBeginAsyncStillImageCapture(viewController: CameraViewController) {
        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            NSNotificationCenter.defaultCenter().postNotificationName("MenuContainerShouldOpen")
            navigationController.popViewControllerAnimated(false)
        }
    }

    func cameraViewController(viewController: CameraViewController, didCaptureStillImage image: UIImage) {
        setUserDefaultProfileImage(image)
    }

    func cameraViewControllerCanceled(viewController: CameraViewController) {
        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            NSNotificationCenter.defaultCenter().postNotificationName("MenuContainerShouldOpen")
            navigationController.popViewControllerAnimated(false)
        }
    }

    func cameraViewControllerShouldOutputFaceMetadata(viewController: CameraViewController) -> Bool {
        return true
    }

    func cameraViewControllerShouldRenderFacialRecognition(viewController: CameraViewController) -> Bool {
        return true
    }

    func cameraViewControllerShouldOutputOCRMetadata(viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewController(viewController: CameraViewController, didSelectImageFromCameraRoll image: UIImage) {

    }

    func cameraViewController(cameraViewController: CameraViewController, didStartVideoCaptureAtURL fileURL: NSURL) {

    }

    func cameraViewController(cameraViewController: CameraViewController, didFinishVideoCaptureAtURL fileURL: NSURL) {

    }

    func cameraViewControllerDidOutputFaceMetadata(viewController: CameraViewController, metadataFaceObject: AVMetadataFaceObject) {

    }

    func cameraViewController(viewController: CameraViewController, didRecognizeText text: String!) {
        
    }

    private func initSelfieViewController() {
        let selfieViewController = UIStoryboard("Camera").instantiateViewControllerWithIdentifier("SelfieViewController") as! SelfieViewController
        selfieViewController.delegate = self

        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            NSNotificationCenter.defaultCenter().postNotificationName("MenuContainerShouldReset")
            navigationController.pushViewController(selfieViewController, animated: false)
        }
    }

    private func setUserDefaultProfileImage(image: UIImage) {
        profileImageUrl = nil

        ApiService.sharedService().setUserDefaultProfileImage(image,
            onSuccess: { statusCode, mappingResult in

            },
            onError: { error, statusCode, responseString in

            }
        )
    }

    // MARK: UIImagePickerControllerDelegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            navigationController.dismissViewController(animated: true) {
                NSNotificationCenter.defaultCenter().postNotificationName("MenuContainerShouldOpen")
            }
        }

        setUserDefaultProfileImage(image)
    }

    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            navigationController.dismissViewController(animated: true) {
                NSNotificationCenter.defaultCenter().postNotificationName("MenuContainerShouldOpen")
            }
        }
    }

    // MARK: UINavigationControllerDelegate

    func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        //UIApplication.sharedApplication().setStatusBarStyle(.LightContent, animated: false)
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
