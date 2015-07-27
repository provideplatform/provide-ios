//
//  ImagePickerViewController.swift
//  provide
//
//  Created by Kyle Thomas on 7/27/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class ImagePickerViewController: UIImagePickerController, UIImagePickerControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()

        sourceType = .SavedPhotosAlbum
        mediaTypes = UIImagePickerController.availableMediaTypesForSourceType(.SavedPhotosAlbum)!
        allowsEditing = false
    }
}
