//
//  SlidingViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class SlidingViewController: ECSlidingViewController {
    
    override var topViewController: UIViewController! {
        didSet {
            topViewController.view.addGestureRecognizer(panGesture)
            topViewAnchoredGesture = .Panning | .Tapping
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        topViewController = UIStoryboard(name: "Application", bundle: nil).instantiateInitialViewController() as! UIViewController
    }
    
    @objc private func hamburgerPressed(sender: UIBarButtonItem) {
        if currentTopViewPosition == .Centered {
            anchorTopViewToRightAnimated(true)
        } else {
            resetTopViewAnimated(true)
        }
    }
    
}
