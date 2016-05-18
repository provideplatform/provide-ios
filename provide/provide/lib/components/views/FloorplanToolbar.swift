//
//  FloorplanToolbar.swift
//  provide
//
//  Created by Kyle Thomas on 10/26/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol FloorplanToolbarDelegate: NSObjectProtocol {
    func floorplanForFloorplanToolbar(toolbar: FloorplanToolbar) -> Floorplan
    func floorplanToolbar(toolbar: FloorplanToolbar, shouldSetFloorplanSelectorVisibility visible: Bool)
    func floorplanToolbar(toolbar: FloorplanToolbar, shouldSetNavigatorVisibility visible: Bool)
    func floorplanToolbar(toolbar: FloorplanToolbar, shouldSetWorkOrdersVisibility visible: Bool, alpha: CGFloat!)
    func floorplanToolbar(toolbar: FloorplanToolbar, shouldSetScaleVisibility visible: Bool)
    func floorplanToolbar(toolbar: FloorplanToolbar, shouldSetFloorplanOptionsVisibility visible: Bool)
    func floorplanShouldBeRenderedAtIndexPath(indexPath: NSIndexPath, forFloorplanToolbar floorplanToolbar: FloorplanToolbar)
    func previousFloorplanShouldBeRenderedForFloorplanToolbar(toolbar: FloorplanToolbar)
    func nextFloorplanShouldBeRenderedForFloorplanToolbar(toolbar: FloorplanToolbar)
    func selectedFloorplanForFloorplanToolbar(toolbar: FloorplanToolbar) -> Floorplan!
    func nextFloorplanButtonShouldBeEnabledForFloorplanToolbar(toolbar: FloorplanToolbar) -> Bool
    func previousFloorplanButtonShouldBeEnabledForFloorplanToolbar(toolbar: FloorplanToolbar) -> Bool
    func scaleCanBeSetByFloorplanToolbar(toolbar: FloorplanToolbar) -> Bool
    func newWorkOrderItemIsShownByFloorplanToolbar(toolbar: FloorplanToolbar) -> Bool
    func newWorkOrderCanBeCreatedByFloorplanToolbar(toolbar: FloorplanToolbar) -> Bool
    func newWorkOrderShouldBeCreatedByFloorplanToolbar(toolbar: FloorplanToolbar)
    func floorplanOptionsItemIsShownByFloorplanToolbar(toolbar: FloorplanToolbar) -> Bool
    func floorplanToolbar(toolbar: FloorplanToolbar, shouldPresentAlertController alertController: UIAlertController)
}

class FloorplanToolbar: UIToolbar {

    var floorplanToolbarDelegate: FloorplanToolbarDelegate!

    private var blueprintSelectorVisible = false
    private var navigatorVisible = false
    private var workOrdersVisible = false
    private var scaleVisible = false
    private var scaleBeingEdited = false
    private var floorplanOptionsVisible = false

    private var isScaleSet: Bool {
        if let floorplan = floorplanToolbarDelegate?.floorplanForFloorplanToolbar(self) {
            if let _ = floorplan.scale {
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
                navigationButton.action = #selector(FloorplanToolbar.previousBlueprint(_:))
                navigationButton.setTitleTextAttributes(previousNextButtonItemTitleTextAttributes, forState: .Normal)
            }
        }
    }

    @IBOutlet private weak var nextBlueprintButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = nextBlueprintButton {
                navigationButton.target = self
                navigationButton.action = #selector(FloorplanToolbar.nextBlueprint(_:))
                navigationButton.setTitleTextAttributes(previousNextButtonItemTitleTextAttributes, forState: .Normal)
            }
        }
    }

    @IBOutlet private weak var blueprintTitleButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = blueprintTitleButton {
                navigationButton.target = self
                navigationButton.action = #selector(FloorplanToolbar.toggleBlueprintSelectorVisibility(_:))
                navigationButton.setTitleTextAttributes(barButtonItemTitleTextAttributes, forState: .Normal)
            }
        }
    }

    @IBOutlet private weak var workOrdersButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = workOrdersButton {
                navigationButton.target = self
                navigationButton.action = #selector(FloorplanToolbar.toggleWorkOrdersVisibility(_:))
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
                navigationButton.action = #selector(FloorplanToolbar.toggleNavigatorVisibility(_:))
                navigationButton.setTitleTextAttributes(barButtonItemTitleTextAttributes, forState: .Normal)
            }
        }
    }

    @IBOutlet private var scaleButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = scaleButton {
                navigationButton.target = self
                navigationButton.action = #selector(FloorplanToolbar.toggleScaleVisibility(_:))
                navigationButton.setTitleTextAttributes(barButtonItemTitleTextAttributes, forState: .Normal)
            }
        }
    }

    @IBOutlet private var createWorkOrderButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = createWorkOrderButton {
                navigationButton.target = self
                navigationButton.action = #selector(FloorplanToolbar.createWorkOrder(_:))
                navigationButton.setTitleTextAttributes(barButtonItemTitleTextAttributes, forState: .Normal)
            }
        }
    }

    @IBOutlet private var floorplanOptionsButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = floorplanOptionsButton {
                navigationButton.target = self
                navigationButton.action = #selector(FloorplanToolbar.toggleFloorplanOptionsVisibility(_:))
                navigationButton.setTitleTextAttributes(barButtonItemTitleTextAttributes, forState: .Normal)
            }
        }
    }

    func reload() {
        if let scaleCanBeSet = floorplanToolbarDelegate?.scaleCanBeSetByFloorplanToolbar(self) {
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

        if let floorplan = floorplanToolbarDelegate?.floorplanForFloorplanToolbar(self) {
            if let scale = floorplan.scale {
                scaleButton.title = "Scale Set: 12“ == \(NSString(format: "%.03f px", scale))"
                scaleButton.setTitleTextAttributes(AppearenceProxy.inProgressBarButtonItemTitleTextAttributes(), forState: .Normal)
            }
        }

        let createWorkOrderButtonVisible = floorplanToolbarDelegate.newWorkOrderItemIsShownByFloorplanToolbar(self)
        let createWorkOrderButtonEnabled = floorplanToolbarDelegate.newWorkOrderCanBeCreatedByFloorplanToolbar(self)
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

        let floorplanOptionsButtonVisible = floorplanToolbarDelegate.floorplanOptionsItemIsShownByFloorplanToolbar(self)
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

        let previousBlueprintButtonEnabled = floorplanToolbarDelegate?.previousFloorplanButtonShouldBeEnabledForFloorplanToolbar(self) ?? false
        let previousBlueprintButtonButtonTitleTextAttribute = previousBlueprintButtonEnabled ? previousNextButtonItemTitleTextAttributes : previousNextButtonItemDisabledTitleTextAttributes
        previousBlueprintButton.setTitleTextAttributes(previousBlueprintButtonButtonTitleTextAttribute, forState: .Normal)
        previousBlueprintButton.enabled = previousBlueprintButtonEnabled

        let nextBlueprintButtonEnabled = floorplanToolbarDelegate?.nextFloorplanButtonShouldBeEnabledForFloorplanToolbar(self) ?? false
        let nextBlueprintButtonButtonTitleTextAttribute = nextBlueprintButtonEnabled ? previousNextButtonItemTitleTextAttributes : previousNextButtonItemDisabledTitleTextAttributes
        nextBlueprintButton.setTitleTextAttributes(nextBlueprintButtonButtonTitleTextAttribute, forState: .Normal)
        nextBlueprintButton.enabled = nextBlueprintButtonEnabled

        let floorplanTitle = floorplanToolbarDelegate?.selectedFloorplanForFloorplanToolbar(self)?.name
        if let floorplanTitle = floorplanTitle {
            blueprintTitleButton?.title = floorplanTitle
            blueprintTitleButton?.enabled = true
        } else {
            //blueprintTitleButton?.enabled = false
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
        floorplanToolbarDelegate?.floorplanToolbar(self, shouldSetNavigatorVisibility: navigatorVisible)

        reload()
    }

    func presentBlueprintAtIndexPath(indexPath: NSIndexPath) {
        toggleBlueprintSelectorVisibility()
        floorplanToolbarDelegate?.floorplanShouldBeRenderedAtIndexPath(indexPath, forFloorplanToolbar: self)
    }

    func nextBlueprint(sender: UIBarButtonItem) {
        floorplanToolbarDelegate?.nextFloorplanShouldBeRenderedForFloorplanToolbar(self)
    }

    func previousBlueprint(sender: UIBarButtonItem) {
        floorplanToolbarDelegate?.previousFloorplanShouldBeRenderedForFloorplanToolbar(self)
    }

    func toggleBlueprintSelectorVisibility(sender: UIBarButtonItem! = nil) {
        blueprintSelectorVisible = !blueprintSelectorVisible
        if blueprintSelectorVisible {
            navigatorVisible = false
            workOrdersVisible = false
        }
        floorplanToolbarDelegate?.floorplanToolbar(self, shouldSetFloorplanSelectorVisibility: blueprintSelectorVisible)

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
        floorplanToolbarDelegate?.floorplanToolbar(self, shouldSetWorkOrdersVisibility: workOrdersVisible, alpha: alpha)
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
        floorplanToolbarDelegate?.floorplanToolbar(self, shouldSetScaleVisibility: scaleVisible)

        reload()
    }

    func toggleScaleVisibility(sender: UIBarButtonItem) {
        toggleScaleVisibility()
    }

    func createWorkOrder(sender: UIBarButtonItem) {
        floorplanToolbarDelegate?.newWorkOrderShouldBeCreatedByFloorplanToolbar(self)

        reload()
    }

    func toggleFloorplanOptionsVisibility() {
        makeFloorplanOptionsVisible(!floorplanOptionsVisible)
    }

    func makeFloorplanOptionsVisible(floorplanOptionsVisible: Bool) {
        self.floorplanOptionsVisible = floorplanOptionsVisible
        floorplanToolbarDelegate?.floorplanToolbar(self, shouldSetFloorplanOptionsVisibility: floorplanOptionsVisible)

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

        floorplanToolbarDelegate?.floorplanToolbar(self, shouldPresentAlertController: alertController)
    }
}
