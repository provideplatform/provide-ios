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

        let user = KeyChainService.sharedService().token!.user
        if user.profileImageUrl == nil {
            initSelfieViewController()
        }
    }

    // MARK: SelfieViewController

    func selfieViewController(viewController: SelfieViewController!, didCaptureStillImage image: UIImage!) {
        navigationController?.popViewControllerAnimated(false)

        let user = KeyChainService.sharedService().token!.user
        let data = UIImageJPEGRepresentation(image, 1.0)

        var params = [
            "public": false,
            "tags": ["profile_image", "default"]
        ]

        ApiService.sharedService().addAttachment(data,
            withMimeType: "image/jpg",
            toUserWithId: user.id.stringValue,
            params: NSDictionary(dictionary: params),
            onSuccess: { statusCode, responseString in

            },
            onError: { statusCode, responseString, error in

            }
        )
    }

    func selfieViewControllerCanceled(viewController: SelfieViewController!) {
        navigationController?.popViewControllerAnimated(false)
    }

    private func initSelfieViewController() {
        let selfieViewController = UIStoryboard("Selfie").instantiateInitialViewController() as! SelfieViewController
        selfieViewController.delegate = self

        navigationController?.pushViewController(selfieViewController, animated: false)
    }
}
