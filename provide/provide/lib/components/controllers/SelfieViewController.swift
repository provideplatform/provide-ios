//
//  SelfieViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class SelfieViewController: CameraViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupFrontCameraView()

        setupNavigationItem()

        view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
    }

    override func setupNavigationItem() {
        navigationItem.title = "TAKE A SELFIE!"
        navigationItem.hidesBackButton = true

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "SKIP", style: .Plain, target: self, action: #selector(SelfieViewController.dismiss(_:)))
    }

    func setupCameraView() {
        setupFrontCameraView()
    }
}
