//
//  ImagePickerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/27/15.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import UIKit

class ImagePickerViewController: UIImagePickerController, UIImagePickerControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        sourceType = .photoLibrary
        mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary)!
        allowsEditing = false
    }

    override var childViewControllerForStatusBarHidden: UIViewController? {
        return nil
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
