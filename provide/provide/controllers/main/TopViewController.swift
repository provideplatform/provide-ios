//
//  TopViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class TopViewController: ViewController, SelfieViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        let viewController = UIStoryboard("Provider").instantiateInitialViewController() as! WorkOrdersViewController
        navigationController?.pushViewController(viewController, animated: false)

        navigationItem.hidesBackButton = true
        navigationController?.setNavigationBarHidden(false, animated: false)

        if currentUser().profileImageUrl == nil {
            initSelfieViewController()
        }
    }

    // MARK: SelfieViewController

    func selfieViewController(viewController: SelfieViewController, didCaptureStillImage image: UIImage) {
        navigationController?.popViewControllerAnimated(false)

        let data = UIImageJPEGRepresentation(image, 1.0)!

        let params = [
            "public": false,
            "tags": ["profile_image", "default"]
        ]

        ApiService.sharedService().addAttachment(data,
            withMimeType: "image/jpg",
            toUserWithId: currentUser().id,
            params: params,
            onSuccess: { statusCode, responseString in
                ApiService.sharedService().fetchUser(onSuccess: { (statusCode, mappingResult) -> () in
                    NSNotificationCenter.defaultCenter().postNotificationName("ProfileImageShouldRefresh")
                }, onError: { (error, statusCode, responseString) -> () in

                })
            },
            onError: { statusCode, responseString, error in

            }
        )
    }

    func selfieViewControllerCanceled(viewController: SelfieViewController) {
        navigationController?.popViewControllerAnimated(false)
    }

    private func initSelfieViewController() {
        let selfieViewController = UIStoryboard("Selfie").instantiateInitialViewController() as! SelfieViewController
        selfieViewController.delegate = self

        navigationController?.pushViewController(selfieViewController, animated: false)
    }
}
