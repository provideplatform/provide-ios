//
//  TopViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import KTSwiftExtensions

class TopViewController: ViewController {

    fileprivate var vc: UIViewController!

    fileprivate var topStoryboard: UIStoryboard! {
        if let mode = KeyChainService.sharedService().mode {
            switch mode {
            case .Customer:
                return UIStoryboard("Customer")
            case .Provider:
                return UIStoryboard("Provider")
            }
        } else {
            // this should never happen...
            logWarn("No user mode resolved... panic!!!") // this should never happen...
        }
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        reload()
    }

    func reload() {
        if let _ = vc {
            navigationController?.setNavigationBarHidden(true, animated: false)
            navigationController?.popViewController(animated: false)
            self.vc = nil
        }

        vc = topStoryboard.instantiateInitialViewController()

        navigationController?.pushViewController(vc, animated: false)

        navigationItem.hidesBackButton = true
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
}
