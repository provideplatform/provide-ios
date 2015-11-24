//
//  BlueprintToolbar.swift
//  provide
//
//  Created by Kyle Thomas on 10/26/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol BlueprintToolbarDelegate {
    func blueprintForBlueprintToolbar(toolbar: BlueprintToolbar) -> Attachment
    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetNavigatorVisibility visible: Bool)
    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetScaleVisibility visible: Bool)
    func newWorkOrderCanBeCreatedByBlueprintToolbar(toolbar: BlueprintToolbar) -> Bool
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
                navigationButton.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
            }
        }
    }

    @IBOutlet private weak var scaleButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = scaleButton {
                navigationButton.target = self
                navigationButton.action = "toggleScaleVisibility:"
                navigationButton.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
            }
        }
    }

    @IBOutlet private weak var createWorkOrderButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = createWorkOrderButton {
                navigationButton.target = self
                navigationButton.action = "createWorkOrder:"
                navigationButton.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
            }
        }
    }

    func reload() {
        let scaleButtonTitleTextAttribute = scaleVisible ? AppearenceProxy.selectedButtonItemTitleTextAttributes() : AppearenceProxy.barButtonItemTitleTextAttributes()
        scaleButton.setTitleTextAttributes(scaleButtonTitleTextAttribute, forState: .Normal)

        let workOrderVisible = blueprintToolbarDelegate.newWorkOrderCanBeCreatedByBlueprintToolbar(self)
        let createWorkOrderButtonTitleTextAttribute = !workOrderVisible ? AppearenceProxy.barButtonItemDisabledTitleTextAttributes() : AppearenceProxy.barButtonItemTitleTextAttributes()
        createWorkOrderButton.setTitleTextAttributes(createWorkOrderButtonTitleTextAttribute, forState: .Normal)
        createWorkOrderButton.enabled = workOrderVisible

        let navigationButtonTitleTextAttribute = navigatorVisible ? AppearenceProxy.selectedButtonItemTitleTextAttributes() : AppearenceProxy.barButtonItemTitleTextAttributes()
        navigationButton.setTitleTextAttributes(navigationButtonTitleTextAttribute, forState: .Normal)

        if let blueprint = blueprintToolbarDelegate?.blueprintForBlueprintToolbar(self) {
            if let scale = blueprint.metadata["scale"] as? Float {
                scaleButton.title = "Scale Set: 12“ == \(NSString(format: "%.03f px", scale))"
                scaleButton.enabled = false
                scaleButton.setTitleTextAttributes(AppearenceProxy.inProgressBarButtonItemTitleTextAttributes(), forState: .Normal)
            }
        }
    }

    func toggleNavigatorVisibility(sender: UIBarButtonItem) {
        navigatorVisible = !navigatorVisible
        blueprintToolbarDelegate?.blueprintToolbar(self, shouldSetNavigatorVisibility: navigatorVisible)

        reload()
    }

    func toggleScaleVisibility() {
        scaleVisible = !scaleVisible
        blueprintToolbarDelegate?.blueprintToolbar(self, shouldSetScaleVisibility: scaleVisible)

        reload()
    }

    func toggleScaleVisibility(sender: UIBarButtonItem) {
        toggleScaleVisibility()
    }

    func createWorkOrder(sender: UIBarButtonItem) {
        blueprintToolbarDelegate?.newWorkOrderShouldBeCreatedByBlueprintToolbar(self)

        reload()
    }
}
