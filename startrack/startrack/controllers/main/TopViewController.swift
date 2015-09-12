//
//  TopViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class TopViewController: ViewController {

    var providerStoryboard: UIStoryboard {
        return UIStoryboard("Provider")
    }

    var castingDirectorStoryboard: UIStoryboard {
        return UIStoryboard("CastingDirector")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let viewController = castingDirectorStoryboard.instantiateInitialViewController()
        viewController!.view.frame = view.bounds

        navigationController?.pushViewController(viewController!, animated: false)

        navigationItem.hidesBackButton = true
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
}
