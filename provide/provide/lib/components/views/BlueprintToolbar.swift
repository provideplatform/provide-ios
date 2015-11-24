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
    func blueprintToolbar(toolbar: BlueprintToolbar, shouldPresentAlertController alertController: UIAlertController)
}

class BlueprintToolbar: UIToolbar {

    var blueprintToolbarDelegate: BlueprintToolbarDelegate!

    private var navigatorVisible = false
    private var scaleVisible = false
    private var scaleBeingEdited = false

    private var isScaleSet: Bool {
        if let blueprint = blueprintToolbarDelegate?.blueprintForBlueprintToolbar(self) {
            if let _ = blueprint.metadata["scale"] as? Float {
                return true
            }
        }
        return false
    }

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
        if isScaleSet && !scaleBeingEdited {
            promptForSetScaleVisibility()
        } else {
            makeScaleVisible(!scaleVisible)
            scaleBeingEdited = false
        }
    }

    func makeScaleVisible(scaleVisible: Bool) {
        self.scaleVisible = scaleVisible
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

    func promptForSetScaleVisibility() {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .Alert : .ActionSheet
        let alertController = UIAlertController(title: "Scale has already been set. Do you really want to set it again?", message: nil, preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)

        let setScaleAction = UIAlertAction(title: "Set Scale", style: .Default) { action in
            self.scaleBeingEdited = true
            self.makeScaleVisible(true)
        }

        alertController.addAction(setScaleAction)

        blueprintToolbarDelegate?.blueprintToolbar(self, shouldPresentAlertController: alertController)
    }
}
