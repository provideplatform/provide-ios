//
//  BlueprintToolbar.swift
//  provide
//
//  Created by Kyle Thomas on 10/26/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol BlueprintToolbarDelegate: NSObjectProtocol {
    func blueprintForBlueprintToolbar(toolbar: BlueprintToolbar) -> Attachment
    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetNavigatorVisibility visible: Bool)
    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetScaleVisibility visible: Bool)
    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetFloorplanOptionsVisibility visible: Bool)
    func scaleCanBeSetByBlueprintToolbar(toolbar: BlueprintToolbar) -> Bool
    func newWorkOrderItemIsShownByBlueprintToolbar(toolbar: BlueprintToolbar) -> Bool
    func newWorkOrderCanBeCreatedByBlueprintToolbar(toolbar: BlueprintToolbar) -> Bool
    func newWorkOrderShouldBeCreatedByBlueprintToolbar(toolbar: BlueprintToolbar)
    func blueprintToolbar(toolbar: BlueprintToolbar, shouldPresentAlertController alertController: UIAlertController)
}

class BlueprintToolbar: UIToolbar {

    weak var blueprintToolbarDelegate: BlueprintToolbarDelegate!

    private var navigatorVisible = false
    private var scaleVisible = false
    private var scaleBeingEdited = false
    private var floorplanOptionsVisible = false

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

    @IBOutlet private var scaleButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = scaleButton {
                navigationButton.target = self
                navigationButton.action = "toggleScaleVisibility:"
                navigationButton.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
            }
        }
    }

    @IBOutlet private var createWorkOrderButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = createWorkOrderButton {
                navigationButton.target = self
                navigationButton.action = "createWorkOrder:"
                navigationButton.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
            }
        }
    }

    @IBOutlet private var floorplanOptionsButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = floorplanOptionsButton {
                navigationButton.target = self
                navigationButton.action = "toggleFloorplanOptionsVisibility:"
                navigationButton.setTitleTextAttributes(AppearenceProxy.barButtonItemTitleTextAttributes(), forState: .Normal)
            }
        }
    }

    func reload() {
        if let scaleCanBeSet = blueprintToolbarDelegate?.scaleCanBeSetByBlueprintToolbar(self) {
            let scaleButtonTitleTextAttribute = scaleVisible ? AppearenceProxy.selectedButtonItemTitleTextAttributes() : AppearenceProxy.barButtonItemTitleTextAttributes()
            scaleButton.setTitleTextAttributes(scaleButtonTitleTextAttribute, forState: .Normal)
            let index = items!.indexOfObject(scaleButton)
            if !scaleCanBeSet {
                if let index = index {
                    items!.removeAtIndex(index)
                }
            } else if index == nil {
                items!.insert(scaleButton, atIndex: 0)
            }
        }

        if let blueprint = blueprintToolbarDelegate?.blueprintForBlueprintToolbar(self) {
            if let scale = blueprint.metadata?["scale"] as? Float {
                scaleButton.title = "Scale Set: 12“ == \(NSString(format: "%.03f px", scale))"
                scaleButton.setTitleTextAttributes(AppearenceProxy.inProgressBarButtonItemTitleTextAttributes(), forState: .Normal)
            }
        }

        let createWorkOrderButtonVisible = blueprintToolbarDelegate.newWorkOrderItemIsShownByBlueprintToolbar(self)
        let createWorkOrderButtonEnabled = blueprintToolbarDelegate.newWorkOrderCanBeCreatedByBlueprintToolbar(self)
        let createWorkOrderButtonTitleTextAttribute = !createWorkOrderButtonEnabled ? AppearenceProxy.barButtonItemDisabledTitleTextAttributes() : AppearenceProxy.barButtonItemTitleTextAttributes()
        createWorkOrderButton.setTitleTextAttributes(createWorkOrderButtonTitleTextAttribute, forState: .Normal)
        if createWorkOrderButtonVisible {
            createWorkOrderButton.enabled = createWorkOrderButtonEnabled

            if items!.indexOfObject(createWorkOrderButton) == nil {
                items!.insert(createWorkOrderButton, atIndex: items!.indexOf(scaleButton) != nil ? 1 : 0)
            }
        } else {
            if let index = items!.indexOfObject(createWorkOrderButton) {
                items!.removeAtIndex(index)
            }
        }

        let floorplanOptionsButtonTitleTextAttribute = floorplanOptionsVisible ? AppearenceProxy.selectedButtonItemTitleTextAttributes() : AppearenceProxy.barButtonItemTitleTextAttributes()
        floorplanOptionsButton.setTitleTextAttributes(floorplanOptionsButtonTitleTextAttribute, forState: .Normal)

        let navigationButtonTitleTextAttribute = navigatorVisible ? AppearenceProxy.selectedButtonItemTitleTextAttributes() : AppearenceProxy.barButtonItemTitleTextAttributes()
        navigationButton.setTitleTextAttributes(navigationButtonTitleTextAttribute, forState: .Normal)
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

    func toggleFloorplanOptionsVisibility() {
        makeFloorplanOptionsVisible(!floorplanOptionsVisible)
    }

    func makeFloorplanOptionsVisible(floorplanOptionsVisible: Bool) {
        self.floorplanOptionsVisible = floorplanOptionsVisible
        blueprintToolbarDelegate?.blueprintToolbar(self, shouldSetFloorplanOptionsVisibility: floorplanOptionsVisible)

        reload()
    }

    func toggleFloorplanOptionsVisibility(sender: UIBarButtonItem) {
        toggleFloorplanOptionsVisibility()
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
