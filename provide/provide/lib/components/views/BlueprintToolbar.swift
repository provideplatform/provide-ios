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
    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetBlueprintSelectorVisibility visible: Bool)
    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetNavigatorVisibility visible: Bool)
    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetWorkOrdersVisibility visible: Bool, alpha: CGFloat!)
    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetScaleVisibility visible: Bool)
    func blueprintToolbar(toolbar: BlueprintToolbar, shouldSetFloorplanOptionsVisibility visible: Bool)
    func previousBlueprintShouldBeRenderedForBlueprintToolbar(toolbar: BlueprintToolbar)
    func nextBlueprintShouldBeRenderedForBlueprintToolbar(toolbar: BlueprintToolbar)
    func selectedBlueprintForBlueprintToolbar(toolbar: BlueprintToolbar) -> Attachment!
    func nextBlueprintButtonShouldBeEnabledForBlueprintToolbar(toolbar: BlueprintToolbar) -> Bool
    func previousBlueprintButtonShouldBeEnabledForBlueprintToolbar(toolbar: BlueprintToolbar) -> Bool
    func scaleCanBeSetByBlueprintToolbar(toolbar: BlueprintToolbar) -> Bool
    func newWorkOrderItemIsShownByBlueprintToolbar(toolbar: BlueprintToolbar) -> Bool
    func newWorkOrderCanBeCreatedByBlueprintToolbar(toolbar: BlueprintToolbar) -> Bool
    func newWorkOrderShouldBeCreatedByBlueprintToolbar(toolbar: BlueprintToolbar)
    func floorplanOptionsItemIsShownByBlueprintToolbar(toolbar: BlueprintToolbar) -> Bool
    func blueprintToolbar(toolbar: BlueprintToolbar, shouldPresentAlertController alertController: UIAlertController)
}

class BlueprintToolbar: UIToolbar {

    var blueprintToolbarDelegate: BlueprintToolbarDelegate!

    private var blueprintSelectorVisible = false
    private var navigatorVisible = false
    private var workOrdersVisible = false
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

    private var barButtonItemTitleTextAttributes: [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 14)!,
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]
    }

    private var selectedButtonItemTitleTextAttributes: [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Bold", size: 14)!,
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]
    }

    private var barButtonItemDisabledTitleTextAttributes: [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Bold", size: 14)!,
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]
    }

    private var previousNextButtonItemTitleTextAttributes: [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Bold", size: 20)!,
            NSForegroundColorAttributeName : UIColor.whiteColor()
        ]
    }

    private var previousNextButtonItemDisabledTitleTextAttributes: [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 20)!,
            NSForegroundColorAttributeName : UIColor.darkGrayColor()
        ]
    }

    @IBOutlet private weak var previousBlueprintButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = previousBlueprintButton {
                navigationButton.target = self
                navigationButton.action = #selector(BlueprintToolbar.previousBlueprint(_:))
                navigationButton.setTitleTextAttributes(previousNextButtonItemTitleTextAttributes, forState: .Normal)
            }
        }
    }

    @IBOutlet private weak var nextBlueprintButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = nextBlueprintButton {
                navigationButton.target = self
                navigationButton.action = #selector(BlueprintToolbar.nextBlueprint(_:))
                navigationButton.setTitleTextAttributes(previousNextButtonItemTitleTextAttributes, forState: .Normal)
            }
        }
    }

    @IBOutlet private weak var blueprintTitleButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = blueprintTitleButton {
                navigationButton.target = self
                navigationButton.action = #selector(BlueprintToolbar.toggleBlueprintSelectorVisibility(_:))
                navigationButton.setTitleTextAttributes(barButtonItemTitleTextAttributes, forState: .Normal)
            }
        }
    }

    @IBOutlet private weak var workOrdersButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = workOrdersButton {
                navigationButton.target = self
                navigationButton.action = #selector(BlueprintToolbar.toggleWorkOrdersVisibility(_:))
                if let image = navigationButton.image {
                    navigationButton.image = image.resize(CGRect(x: 0.0, y: 0.0, width: 25.0, height: 31.0))
                }
                navigationButton.setTitleTextAttributes(barButtonItemTitleTextAttributes, forState: .Normal)
            }
        }
    }

    @IBOutlet private weak var navigationButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = navigationButton {
                navigationButton.target = self
                navigationButton.action = #selector(BlueprintToolbar.toggleNavigatorVisibility(_:))
                navigationButton.setTitleTextAttributes(barButtonItemTitleTextAttributes, forState: .Normal)
            }
        }
    }

    @IBOutlet private var scaleButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = scaleButton {
                navigationButton.target = self
                navigationButton.action = #selector(BlueprintToolbar.toggleScaleVisibility(_:))
                navigationButton.setTitleTextAttributes(barButtonItemTitleTextAttributes, forState: .Normal)
            }
        }
    }

    @IBOutlet private var createWorkOrderButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = createWorkOrderButton {
                navigationButton.target = self
                navigationButton.action = #selector(BlueprintToolbar.createWorkOrder(_:))
                navigationButton.setTitleTextAttributes(barButtonItemTitleTextAttributes, forState: .Normal)
            }
        }
    }

    @IBOutlet private var floorplanOptionsButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = floorplanOptionsButton {
                navigationButton.target = self
                navigationButton.action = #selector(BlueprintToolbar.toggleFloorplanOptionsVisibility(_:))
                navigationButton.setTitleTextAttributes(barButtonItemTitleTextAttributes, forState: .Normal)
            }
        }
    }

    func reload() {
        if let scaleCanBeSet = blueprintToolbarDelegate?.scaleCanBeSetByBlueprintToolbar(self) {
            let scaleButtonTitleTextAttribute = scaleVisible ? selectedButtonItemTitleTextAttributes : barButtonItemTitleTextAttributes
            scaleButton.setTitleTextAttributes(scaleButtonTitleTextAttribute, forState: .Normal)
            let index = items!.indexOfObject(scaleButton)
            if !scaleCanBeSet {
                if let index = index {
                    items!.removeAtIndex(index)
                }
            } else if index == nil {
                items!.insert(scaleButton, atIndex: 0)
            }
        } else if let index = items!.indexOfObject(scaleButton) {
            items!.removeAtIndex(index)
        }

        if let blueprint = blueprintToolbarDelegate?.blueprintForBlueprintToolbar(self) {
            if let scale = blueprint.metadata?["scale"] as? Float {
                scaleButton.title = "Scale Set: 12“ == \(NSString(format: "%.03f px", scale))"
                scaleButton.setTitleTextAttributes(AppearenceProxy.inProgressBarButtonItemTitleTextAttributes(), forState: .Normal)
            }
        }

        let createWorkOrderButtonVisible = blueprintToolbarDelegate.newWorkOrderItemIsShownByBlueprintToolbar(self)
        let createWorkOrderButtonEnabled = blueprintToolbarDelegate.newWorkOrderCanBeCreatedByBlueprintToolbar(self)
        let createWorkOrderButtonTitleTextAttribute = !createWorkOrderButtonEnabled ? barButtonItemDisabledTitleTextAttributes : barButtonItemTitleTextAttributes
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

        let floorplanOptionsButtonVisible = blueprintToolbarDelegate.floorplanOptionsItemIsShownByBlueprintToolbar(self)
        let floorplanOptionsButtonTitleTextAttribute = floorplanOptionsVisible ? selectedButtonItemTitleTextAttributes : barButtonItemTitleTextAttributes
        floorplanOptionsButton.setTitleTextAttributes(floorplanOptionsButtonTitleTextAttribute, forState: .Normal)
        if !floorplanOptionsButtonVisible {
            if let index = items!.indexOfObject(floorplanOptionsButton) {
                items!.removeAtIndex(index)
            }
        }

        let navigationButtonTitleTextAttribute = navigatorVisible ? selectedButtonItemTitleTextAttributes : barButtonItemTitleTextAttributes
        navigationButton.setTitleTextAttributes(navigationButtonTitleTextAttribute, forState: .Normal)

        let blueprintSelectorButtonTitleTextAttribute = blueprintSelectorVisible ? selectedButtonItemTitleTextAttributes : barButtonItemTitleTextAttributes
        blueprintTitleButton?.setTitleTextAttributes(blueprintSelectorButtonTitleTextAttribute, forState: .Normal)

        let previousBlueprintButtonEnabled = blueprintToolbarDelegate?.previousBlueprintButtonShouldBeEnabledForBlueprintToolbar(self) ?? false
        let previousBlueprintButtonButtonTitleTextAttribute = previousBlueprintButtonEnabled ? previousNextButtonItemTitleTextAttributes : previousNextButtonItemDisabledTitleTextAttributes
        previousBlueprintButton.setTitleTextAttributes(previousBlueprintButtonButtonTitleTextAttribute, forState: .Normal)
        previousBlueprintButton.enabled = previousBlueprintButtonEnabled

        let nextBlueprintButtonEnabled = blueprintToolbarDelegate?.nextBlueprintButtonShouldBeEnabledForBlueprintToolbar(self) ?? false
        let nextBlueprintButtonButtonTitleTextAttribute = nextBlueprintButtonEnabled ? previousNextButtonItemTitleTextAttributes : previousNextButtonItemDisabledTitleTextAttributes
        nextBlueprintButton.setTitleTextAttributes(nextBlueprintButtonButtonTitleTextAttribute, forState: .Normal)
        nextBlueprintButton.enabled = nextBlueprintButtonEnabled

        let blueprintTitle = blueprintToolbarDelegate?.selectedBlueprintForBlueprintToolbar(self)?.filename
        if let blueprintTitle = blueprintTitle {
            blueprintTitleButton?.title = blueprintTitle
        } else {
            blueprintTitleButton?.enabled = false
        }

        if isIPhone() {
            if let blueprintTitleButton = blueprintTitleButton {
                if let index = items!.indexOfObject(blueprintTitleButton) {
                    items!.removeAtIndex(index)
                }
            }
        }
    }

    func toggleNavigatorVisibility(sender: UIBarButtonItem) {
        navigatorVisible = !navigatorVisible
        if navigatorVisible {
            workOrdersVisible = false
        }
        blueprintToolbarDelegate?.blueprintToolbar(self, shouldSetNavigatorVisibility: navigatorVisible)

        reload()
    }

    func nextBlueprint(sender: UIBarButtonItem) {
        blueprintToolbarDelegate?.nextBlueprintShouldBeRenderedForBlueprintToolbar(self)
    }

    func previousBlueprint(sender: UIBarButtonItem) {
        blueprintToolbarDelegate?.previousBlueprintShouldBeRenderedForBlueprintToolbar(self)
    }

    func toggleBlueprintSelectorVisibility(sender: UIBarButtonItem) {
        blueprintSelectorVisible = !blueprintSelectorVisible
        if blueprintSelectorVisible {
            navigatorVisible = false
            workOrdersVisible = false
        }
        blueprintToolbarDelegate?.blueprintToolbar(self, shouldSetBlueprintSelectorVisibility: blueprintSelectorVisible)

        reload()
    }

    func toggleWorkOrdersVisibility(sender: UIBarButtonItem) {
        toggleWorkOrdersVisibility()
    }

    func toggleWorkOrdersVisibility() {
        setWorkOrdersVisibility(!workOrdersVisible)
    }

    func setWorkOrdersVisibility(workOrdersVisible: Bool, alpha: CGFloat! = nil) {
        self.workOrdersVisible = workOrdersVisible
        if self.workOrdersVisible {
            navigatorVisible = false
        }
        blueprintToolbarDelegate?.blueprintToolbar(self, shouldSetWorkOrdersVisibility: workOrdersVisible, alpha: alpha)
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
