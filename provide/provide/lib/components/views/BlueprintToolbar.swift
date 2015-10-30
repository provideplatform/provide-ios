//
//  BlueprintToolbar.swift
//  provide
//
//  Created by Kyle Thomas on 10/26/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol BlueprintToolbarDelegate {
    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetNavigatorVisibility visible: Bool)
    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetScaleVisibility visible: Bool)
}

class BlueprintToolbar: UIToolbar {

    var blueprintToolbarDelegate: BlueprintToolbarDelegate!

    private var navigatorVisible = false
    private var scaleVisible = false

    @IBOutlet private weak var navigationButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = navigationButton {
                navigationButton.target = self
                navigationButton.action = "toggleNavigatorVisibility:"
            }
        }
    }

    @IBOutlet private weak var scaleButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = scaleButton {
                navigationButton.target = self
                navigationButton.action = "toggleScaleVisibility:"
            }
        }
    }

    func toggleNavigatorVisibility(sender: UIBarButtonItem) {
        navigatorVisible = !navigatorVisible
        blueprintToolbarDelegate?.blueprintToolbar(self, shouldSetNavigatorVisibility: navigatorVisible)
    }

    func toggleScaleVisibility(sender: UIBarButtonItem) {
        scaleVisible = !scaleVisible
        blueprintToolbarDelegate?.blueprintToolbar(self, shouldSetScaleVisibility: scaleVisible)
    }
}
