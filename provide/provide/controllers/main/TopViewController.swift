//
//  TopViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class TopViewController: ViewController, CameraViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        let viewController = UIStoryboard("Provider").instantiateInitialViewController() as! WorkOrdersViewController
        viewController.view.frame = view.bounds

        navigationController?.pushViewController(viewController, animated: false)

        navigationItem.hidesBackButton = true
        navigationController?.setNavigationBarHidden(false, animated: false)

        if currentUser().profileImageUrl == nil {
            initSelfieViewController()
        }
    }

    // MARK: SelfieViewController

    func cameraViewController(viewController: CameraViewController, didCaptureStillImage image: UIImage) {
        navigationController?.popViewControllerAnimated(false)

        ApiService.sharedService().setUserDefaultProfileImage(image,
            onSuccess: { statusCode, mappingResult in

            },
            onError: { error, statusCode, responseString in

            }
        )
    }

    func cameraViewControllerCanceled(viewController: CameraViewController) {
        navigationController?.popViewControllerAnimated(false)
    }

    private func initSelfieViewController() {
        let selfieViewController = UIStoryboard("Camera").instantiateViewControllerWithIdentifier("SelfieViewController") as! SelfieViewController
        selfieViewController.delegate = self

        navigationController?.pushViewController(selfieViewController, animated: false)
    }
}
