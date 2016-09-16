//
//  TopViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class TopViewController: ViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let viewController = UIStoryboard("Provider").instantiateInitialViewController() as! WorkOrdersViewController
        viewController.view.frame = view.bounds

        navigationController?.pushViewController(viewController, animated: false)

        navigationItem.hidesBackButton = true
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
}
