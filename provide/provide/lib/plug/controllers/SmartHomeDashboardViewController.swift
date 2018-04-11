//
//  SmartHomeDashboardViewController.swift
//  provide
//
//  Created by Kyle Thomas on 4/10/18
//  Copyright © 2018 Provide Technologies Inc. All rights reserved.
//

import UIKit

class SmartHomeDashboardViewController: ViewController, MenuViewControllerDelegate, WorkOrderHistoryViewControllerDelegate {

    private var zeroStateViewController = UIStoryboard("ZeroState").instantiateInitialViewController() as! ZeroStateViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        // TODO: fetch active reservation
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        UIApplication.shared.statusBarStyle = .default
        navigationController?.navigationBar.backgroundColor = Color.applicationDefaultNavigationBarBackgroundColor()
        navigationController?.navigationBar.barTintColor = nil
        navigationController?.navigationBar.tintColor = nil
    }
}
