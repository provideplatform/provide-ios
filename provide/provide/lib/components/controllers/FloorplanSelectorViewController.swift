//
//  FloorplanSelectorViewController.swift
//  provide
//
//  Created by Kyle Thomas on 4/30/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class FloorplanSelectorViewController: ViewController {

    weak var selectorView: FloorplanSelectorView! {
        return view as? FloorplanSelectorView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        selectorView!.backgroundColor = UIColor.whiteColor()
        selectorView!.roundCorners(5.0)
        selectorView!.alpha = 0.0
    }
}
