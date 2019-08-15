//
//  CustomHeightModalTransitioningDelegate.swift
//  provide
//
//  Created by Jawwad Ahmad on 10/30/17.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import Foundation

class CustomHeightModalTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

    private var height: CGFloat

    init(height: CGFloat) {
        self.height = height
    }

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return CustomHeightModalPresentationController(height: height, presentedViewController: presented, presenting: presenting)
    }
}
