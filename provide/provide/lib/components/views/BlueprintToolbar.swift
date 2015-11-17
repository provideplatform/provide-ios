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
    func newWorkOrderShouldBeCreatedByBlueprintToolbar(toolbar: BlueprintToolbar)
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

    @IBOutlet private weak var createWorkOrderButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = createWorkOrderButton {
                navigationButton.target = self
                navigationButton.action = "createWorkOrder:"
            }
        }
    }

    func toggleNavigatorVisibility(sender: UIBarButtonItem) {
        navigatorVisible = !navigatorVisible
        blueprintToolbarDelegate?.blueprintToolbar(self, shouldSetNavigatorVisibility: navigatorVisible)
    }

    func toggleScaleVisibility() {
        scaleVisible = !scaleVisible
        blueprintToolbarDelegate?.blueprintToolbar(self, shouldSetScaleVisibility: scaleVisible)
    }

    func toggleScaleVisibility(sender: UIBarButtonItem) {
        toggleScaleVisibility()
    }

    func createWorkOrder(sender: UIBarButtonItem) {
        blueprintToolbarDelegate?.newWorkOrderShouldBeCreatedByBlueprintToolbar(self)
    }
}
