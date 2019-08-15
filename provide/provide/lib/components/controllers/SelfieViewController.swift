//
//  SelfieViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import UIKit

class SelfieViewController: CameraViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupFrontCameraView()

        setupNavigationItem()

        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }

    override func setupNavigationItem() {
        navigationItem.title = "TAKE A SELFIE!"
        navigationItem.hidesBackButton = true

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "SKIP", style: .plain, target: self, action: #selector(dismiss(_:)))
    }

    private func setupCameraView() {
        setupFrontCameraView()
    }
}
