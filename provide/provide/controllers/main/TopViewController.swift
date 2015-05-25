//
//  TopViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class TopViewController: ViewController, SelfieViewControllerDelegate {

    private var childViewController: ViewController!

    private let defaultInitialStoryboardName = "Provider"

    private var initialStoryboard: UIStoryboard! {
        let storyboardName = ENV("INITIAL_STORYBOARD") ?? defaultInitialStoryboardName
        return UIStoryboard(storyboardName)
    }

    private var selfieViewController: SelfieViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        childViewController = initialStoryboard?.instantiateInitialViewController() as! ViewController
        navigationController?.pushViewController(childViewController, animated: false)

        navigationItem.hidesBackButton = true
        navigationController?.setNavigationBarHidden(false, animated: false)

        if let user = KeyChainService.sharedService().token?.user {
            if user.profileImageUrl == nil {
                initSelfieViewController()
            }
        }
    }

    // MARK: SelfieViewController

    func selfieViewController(viewController: SelfieViewController!, didCaptureStillImage image: UIImage!) {
        navigationController?.popViewControllerAnimated(false)

        if let user = KeyChainService.sharedService().token?.user {
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
    }

    func selfieViewControllerCanceled(viewController: SelfieViewController!) {
        navigationController?.popViewControllerAnimated(false)
    }

    private func initSelfieViewController() {
        selfieViewController = UIStoryboard("Selfie").instantiateInitialViewController() as! SelfieViewController
        selfieViewController.delegate = self

        navigationController?.pushViewController(selfieViewController, animated: false)
    }
}
