//
//  BlueprintSelectorViewController.swift
//  provide
//
//  Created by Kyle Thomas on 4/30/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class BlueprintSelectorViewController: ViewController {

    weak var selectorView: BlueprintSelectorView! {
        return view as? BlueprintSelectorView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        selectorView!.backgroundColor = UIColor.whiteColor()
        selectorView!.roundCorners(5.0)
        selectorView!.alpha = 0.0
    }
}
