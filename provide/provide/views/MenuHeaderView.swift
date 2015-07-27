//
//  MenuHeaderView.swift
//  provide
//
//  Created by Kyle Thomas on 7/27/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol MenuHeaderViewDelegate {
    func navigationViewControllerForMenuHeaderView(view: MenuHeaderView) -> UINavigationController!
}

class MenuHeaderView: UIView, UIActionSheetDelegate, CameraViewControllerDelegate {

    var delegate: MenuHeaderViewDelegate!

    @IBOutlet private weak var profileImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var changeProfileImageButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = UIColor.clearColor()

        profileImageUrl = currentUser().profileImageUrl
        nameLabel.text = currentUser().name

        changeProfileImageButton.addTarget(self, action: "changeProfileImage", forControlEvents: .TouchUpInside)

        NSNotificationCenter.defaultCenter().addObserverForName("ProfileImageShouldRefresh") { _ in
            self.profileImageUrl = currentUser().profileImageUrl
        }
    }

    var profileImageUrl: NSURL! {
        didSet {
            if let profileImageUrl = profileImageUrl {
                profileImageView.contentMode = .ScaleAspectFit
                profileImageView.sd_setImageWithURL(profileImageUrl, completed: { (image, error, imageCacheType, url) -> Void in
                    self.bringSubviewToFront(self.profileImageView)
                    self.profileImageView.makeCircular()
                    self.profileImageView.alpha = 1.0
                })
            } else {
                profileImageView.image = nil
                profileImageView.alpha = 0.0
            }
        }
    }

    func changeProfileImage() {
        var actionSheet = UIActionSheet(title: "Want to take a selfie or choose from your camera roll?", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil)
        actionSheet.addButtonWithTitle("Selfie")
        actionSheet.addButtonWithTitle("Camera Roll")

        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            actionSheet.showInView(navigationController.view)
        }
    }

    // MARK: UIActionSheetDelegate

    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 0 {
            println("init photo library")
        } else if buttonIndex == 1 {
            initSelfieViewController()
        }
    }

    // MARK: SelfieViewControllerDelegate

    func cameraViewController(viewController: CameraViewController!, didCaptureStillImage image: UIImage!) {
        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            NSNotificationCenter.defaultCenter().postNotificationName("MenuContainerShouldOpen")
            navigationController.popViewControllerAnimated(false)
        }

        ApiService.sharedService().setUserDefaultProfileImage(image,
            onSuccess: { statusCode, mappingResult in

            },
            onError: { error, statusCode, responseString in

            }
        )
    }

    func cameraViewControllerCanceled(viewController: CameraViewController!) {
        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            NSNotificationCenter.defaultCenter().postNotificationName("MenuContainerShouldOpen")
            navigationController.popViewControllerAnimated(false)
        }
    }

    private func initSelfieViewController() {
        let selfieViewController = UIStoryboard("Camera").instantiateViewControllerWithIdentifier("SelfieViewController") as! SelfieViewController
        selfieViewController.delegate = self

        if let navigationController = delegate?.navigationViewControllerForMenuHeaderView(self) {
            NSNotificationCenter.defaultCenter().postNotificationName("MenuContainerShouldReset")
            navigationController.pushViewController(selfieViewController, animated: false)
        }
    }

//    // Called when we cancel a view (eg. the user clicks the Home button). This is not called when the user clicks the cancel button.
//    // If not defined in the delegate, we simulate a click in the cancel button
//    optional func actionSheetCancel(actionSheet: UIActionSheet)
//
//    optional func willPresentActionSheet(actionSheet: UIActionSheet) // before animation and showing view
//    optional func didPresentActionSheet(actionSheet: UIActionSheet) // after animation
//
//    optional func actionSheet(actionSheet: UIActionSheet, willDismissWithButtonIndex buttonIndex: Int) // before animation and hiding view
//    optional func actionSheet(actionSheet: UIActionSheet, didDismissWithButtonIndex buttonIndex: Int) // after animation
}
