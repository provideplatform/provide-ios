//
//  BlueprintThumbnailViewController.swift
//  provide
//
//  Created by Kyle Thomas on 11/24/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class BlueprintThumbnailViewController: ViewController {

    weak var thumbnailView: BlueprintThumbnailView! {
        return view as? BlueprintThumbnailView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        thumbnailView!.backgroundColor = UIColor.whiteColor()
        thumbnailView!.roundCorners(5.0)
        thumbnailView!.alpha = 0.0
    }
}
