//
//  TopViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class TopViewController: ViewController {

    var topStoryboard: UIStoryboard! {
        didSet {
            let viewController = topStoryboard.instantiateInitialViewController()
            viewController!.view.frame = view.bounds

            navigationController?.popToRootViewControllerAnimated(false)
            navigationController?.pushViewController(viewController!, animated: false)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
}
