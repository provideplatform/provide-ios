//
//  FloorplanThumbnailViewController.swift
//  provide
//
//  Created by Kyle Thomas on 11/24/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class FloorplanThumbnailViewController: ViewController {

    weak var thumbnailView: FloorplanThumbnailView! {
        return view as? FloorplanThumbnailView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        thumbnailView!.backgroundColor = UIColor.white
        thumbnailView!.roundCorners(5.0)
        thumbnailView!.alpha = 0.0
    }
}
