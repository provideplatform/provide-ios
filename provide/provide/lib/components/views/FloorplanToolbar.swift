//
//  FloorplanToolbar.swift
//  provide
//
//  Created by Kyle Thomas on 10/26/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

protocol FloorplanToolbarDelegate: NSObjectProtocol {
    func floorplanForFloorplanToolbar(_ toolbar: FloorplanToolbar) -> Floorplan
    func floorplanToolbar(_ toolbar: FloorplanToolbar, shouldSetFloorplanSelectorVisibility visible: Bool)
    func floorplanToolbar(_ toolbar: FloorplanToolbar, shouldSetNavigatorVisibility visible: Bool)
    func floorplanToolbar(_ toolbar: FloorplanToolbar, shouldSetWorkOrdersVisibility visible: Bool, alpha: CGFloat!)
    func floorplanToolbar(_ toolbar: FloorplanToolbar, shouldSetScaleVisibility visible: Bool)
    func floorplanToolbar(_ toolbar: FloorplanToolbar, shouldSetFloorplanOptionsVisibility visible: Bool)
    func floorplanShouldBeRenderedAtIndexPath(_ indexPath: IndexPath, forFloorplanToolbar floorplanToolbar: FloorplanToolbar)
    func previousFloorplanShouldBeRenderedForFloorplanToolbar(_ toolbar: FloorplanToolbar)
    func nextFloorplanShouldBeRenderedForFloorplanToolbar(_ toolbar: FloorplanToolbar)
    func selectedFloorplanForFloorplanToolbar(_ toolbar: FloorplanToolbar) -> Floorplan!
    func nextFloorplanButtonShouldBeEnabledForFloorplanToolbar(_ toolbar: FloorplanToolbar) -> Bool
    func previousFloorplanButtonShouldBeEnabledForFloorplanToolbar(_ toolbar: FloorplanToolbar) -> Bool
    func scaleCanBeSetByFloorplanToolbar(_ toolbar: FloorplanToolbar) -> Bool
    func newWorkOrderItemIsShownByFloorplanToolbar(_ toolbar: FloorplanToolbar) -> Bool
    func newWorkOrderCanBeCreatedByFloorplanToolbar(_ toolbar: FloorplanToolbar) -> Bool
    func newWorkOrderShouldBeCreatedByFloorplanToolbar(_ toolbar: FloorplanToolbar)
    func floorplanOptionsItemIsShownByFloorplanToolbar(_ toolbar: FloorplanToolbar) -> Bool
    func floorplanToolbar(_ toolbar: FloorplanToolbar, shouldPresentAlertController alertController: UIAlertController)
}

class FloorplanToolbar: UIToolbar {

    var floorplanToolbarDelegate: FloorplanToolbarDelegate!

    fileprivate var floorplanSelectorVisible = false
    fileprivate var navigatorVisible = false
    fileprivate var workOrdersVisible = false
    fileprivate var scaleVisible = false
    fileprivate var scaleBeingEdited = false
    fileprivate var floorplanOptionsVisible = false

    fileprivate var isScaleSet: Bool {
        if let floorplan = floorplanToolbarDelegate?.floorplanForFloorplanToolbar(self) {
            if let _ = floorplan.scale {
                return true
            }
        }
        return false
    }

    fileprivate var barButtonItemTitleTextAttributes: [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 14)!,
            NSForegroundColorAttributeName : UIColor.white
        ]
    }

    fileprivate var selectedButtonItemTitleTextAttributes: [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Bold", size: 14)!,
            NSForegroundColorAttributeName : UIColor.white
        ]
    }

    fileprivate var barButtonItemDisabledTitleTextAttributes: [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Bold", size: 14)!,
            NSForegroundColorAttributeName : UIColor.white
        ]
    }

    fileprivate var previousNextButtonItemTitleTextAttributes: [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Bold", size: 20)!,
            NSForegroundColorAttributeName : UIColor.white
        ]
    }

    fileprivate var previousNextButtonItemDisabledTitleTextAttributes: [String : AnyObject] {
        return [
            NSFontAttributeName : UIFont(name: "Exo2-Light", size: 20)!,
            NSForegroundColorAttributeName : UIColor.darkGray
        ]
    }

    @IBOutlet fileprivate weak var previousFloorplanButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = previousFloorplanButton {
                navigationButton.target = self
                navigationButton.action = #selector(FloorplanToolbar.previousFloorplan(_:))
                navigationButton.setTitleTextAttributes(previousNextButtonItemTitleTextAttributes, for: UIControlState())
            }
        }
    }

    @IBOutlet fileprivate weak var nextFloorplanButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = nextFloorplanButton {
                navigationButton.target = self
                navigationButton.action = #selector(FloorplanToolbar.nextFloorplan(_:))
                navigationButton.setTitleTextAttributes(previousNextButtonItemTitleTextAttributes, for: UIControlState())
            }
        }
    }

    @IBOutlet fileprivate weak var floorplanTitleButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = floorplanTitleButton {
                navigationButton.target = self
                navigationButton.action = #selector(FloorplanToolbar.toggleFloorplanSelectorVisibility(_:))
                navigationButton.setTitleTextAttributes(barButtonItemTitleTextAttributes, for: UIControlState())
            }
        }
    }

    @IBOutlet fileprivate weak var workOrdersButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = workOrdersButton {
                navigationButton.target = self
                navigationButton.action = #selector(FloorplanToolbar.toggleWorkOrdersVisibility(_:))
                if let image = navigationButton.image {
                    navigationButton.image = image.resize(CGRect(x: 0.0, y: 0.0, width: 25.0, height: 31.0))
                }
                navigationButton.setTitleTextAttributes(barButtonItemTitleTextAttributes, for: UIControlState())
            }
        }
    }

    @IBOutlet fileprivate weak var navigationButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = navigationButton {
                navigationButton.target = self
                navigationButton.action = #selector(FloorplanToolbar.toggleNavigatorVisibility(_:))
                navigationButton.setTitleTextAttributes(barButtonItemTitleTextAttributes, for: UIControlState())
            }
        }
    }

    @IBOutlet fileprivate var scaleButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = scaleButton {
                navigationButton.target = self
                navigationButton.action = #selector(FloorplanToolbar.toggleScaleVisibility(_:))
                navigationButton.setTitleTextAttributes(barButtonItemTitleTextAttributes, for: UIControlState())
            }
        }
    }

    @IBOutlet fileprivate var createWorkOrderButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = createWorkOrderButton {
                navigationButton.target = self
                navigationButton.action = #selector(FloorplanToolbar.createWorkOrder(_:))
                navigationButton.setTitleTextAttributes(barButtonItemTitleTextAttributes, for: UIControlState())
            }
        }
    }

    @IBOutlet fileprivate var floorplanOptionsButton: UIBarButtonItem! {
        didSet {
            if let navigationButton = floorplanOptionsButton {
                navigationButton.target = self
                navigationButton.action = #selector(FloorplanToolbar.toggleFloorplanOptionsVisibility(_:))
                navigationButton.setTitleTextAttributes(barButtonItemTitleTextAttributes, for: UIControlState())
            }
        }
    }

    func reload() {
        if let scaleCanBeSet = floorplanToolbarDelegate?.scaleCanBeSetByFloorplanToolbar(self) {
            let scaleButtonTitleTextAttribute = scaleVisible ? selectedButtonItemTitleTextAttributes : barButtonItemTitleTextAttributes
            scaleButton.setTitleTextAttributes(scaleButtonTitleTextAttribute, for: UIControlState())
            let index = items!.indexOfObject(scaleButton)
            if !scaleCanBeSet {
                if let index = index {
                    items!.remove(at: index)
                }
            } else if index == nil {
                items!.insert(scaleButton, at: 0)
            }
        } else if let index = items!.indexOfObject(scaleButton) {
            items!.remove(at: index)
        }

        if let floorplan = floorplanToolbarDelegate?.floorplanForFloorplanToolbar(self) {
            if let scale = floorplan.scale {
                scaleButton.title = "Scale Set: 12“ == \(NSString(format: "%.03f px", scale))"
                scaleButton.setTitleTextAttributes(AppearenceProxy.inProgressBarButtonItemTitleTextAttributes(), for: UIControlState())
            }
        }

        let createWorkOrderButtonVisible = floorplanToolbarDelegate.newWorkOrderItemIsShownByFloorplanToolbar(self)
        let createWorkOrderButtonEnabled = floorplanToolbarDelegate.newWorkOrderCanBeCreatedByFloorplanToolbar(self)
        let createWorkOrderButtonTitleTextAttribute = !createWorkOrderButtonEnabled ? barButtonItemDisabledTitleTextAttributes : barButtonItemTitleTextAttributes
        createWorkOrderButton.setTitleTextAttributes(createWorkOrderButtonTitleTextAttribute, for: UIControlState())
        if createWorkOrderButtonVisible {
            createWorkOrderButton.isEnabled = createWorkOrderButtonEnabled

            if items!.indexOfObject(createWorkOrderButton) == nil {
                items!.insert(createWorkOrderButton, at: items!.index(of: scaleButton) != nil ? 1 : 0)
            }
        } else {
            if let index = items!.indexOfObject(createWorkOrderButton) {
                items!.remove(at: index)
            }
        }

        let floorplanOptionsButtonVisible = floorplanToolbarDelegate.floorplanOptionsItemIsShownByFloorplanToolbar(self)
        let floorplanOptionsButtonTitleTextAttribute = floorplanOptionsVisible ? selectedButtonItemTitleTextAttributes : barButtonItemTitleTextAttributes
        floorplanOptionsButton.setTitleTextAttributes(floorplanOptionsButtonTitleTextAttribute, for: UIControlState())
        if !floorplanOptionsButtonVisible {
            if let index = items!.indexOfObject(floorplanOptionsButton) {
                items!.remove(at: index)
            }
        }

        let navigationButtonTitleTextAttribute = navigatorVisible ? selectedButtonItemTitleTextAttributes : barButtonItemTitleTextAttributes
        navigationButton.setTitleTextAttributes(navigationButtonTitleTextAttribute, for: UIControlState())

        let floorplanSelectorButtonTitleTextAttribute = floorplanSelectorVisible ? selectedButtonItemTitleTextAttributes : barButtonItemTitleTextAttributes
        floorplanTitleButton?.setTitleTextAttributes(floorplanSelectorButtonTitleTextAttribute, for: UIControlState())

        let previousFloorplanButtonEnabled = floorplanToolbarDelegate?.previousFloorplanButtonShouldBeEnabledForFloorplanToolbar(self) ?? false
        let previousFloorplanButtonButtonTitleTextAttribute = previousFloorplanButtonEnabled ? previousNextButtonItemTitleTextAttributes : previousNextButtonItemDisabledTitleTextAttributes
        previousFloorplanButton.setTitleTextAttributes(previousFloorplanButtonButtonTitleTextAttribute, for: UIControlState())
        previousFloorplanButton.isEnabled = previousFloorplanButtonEnabled

        let nextFloorplanButtonEnabled = floorplanToolbarDelegate?.nextFloorplanButtonShouldBeEnabledForFloorplanToolbar(self) ?? false
        let nextFloorplanButtonButtonTitleTextAttribute = nextFloorplanButtonEnabled ? previousNextButtonItemTitleTextAttributes : previousNextButtonItemDisabledTitleTextAttributes
        nextFloorplanButton.setTitleTextAttributes(nextFloorplanButtonButtonTitleTextAttribute, for: UIControlState())
        nextFloorplanButton.isEnabled = nextFloorplanButtonEnabled

        let floorplanTitle = floorplanToolbarDelegate?.selectedFloorplanForFloorplanToolbar(self)?.name
        if let floorplanTitle = floorplanTitle {
            floorplanTitleButton?.title = floorplanTitle
            floorplanTitleButton?.isEnabled = true
        } else {
            //floorplanTitleButton?.enabled = false
        }

        if isIPhone() {
            if let floorplanTitleButton = floorplanTitleButton {
                if let index = items!.indexOfObject(floorplanTitleButton) {
                    items!.remove(at: index)
                }
            }
        }
    }

    func toggleNavigatorVisibility(_ sender: UIBarButtonItem) {
        navigatorVisible = !navigatorVisible
        if navigatorVisible {
            floorplanSelectorVisible = false
            workOrdersVisible = false
        }
        floorplanToolbarDelegate?.floorplanToolbar(self, shouldSetNavigatorVisibility: navigatorVisible)

        reload()
    }

    func presentFloorplanAtIndexPath(_ indexPath: IndexPath) {
        toggleFloorplanSelectorVisibility()
        floorplanToolbarDelegate?.floorplanShouldBeRenderedAtIndexPath(indexPath, forFloorplanToolbar: self)
    }

    func nextFloorplan(_ sender: UIBarButtonItem) {
        floorplanToolbarDelegate?.nextFloorplanShouldBeRenderedForFloorplanToolbar(self)
    }

    func previousFloorplan(_ sender: UIBarButtonItem) {
        floorplanToolbarDelegate?.previousFloorplanShouldBeRenderedForFloorplanToolbar(self)
    }

    func toggleFloorplanSelectorVisibility(_ sender: UIBarButtonItem! = nil) {
        floorplanSelectorVisible = !floorplanSelectorVisible
        if floorplanSelectorVisible {
            navigatorVisible = false
            workOrdersVisible = false
        }
        floorplanToolbarDelegate?.floorplanToolbar(self, shouldSetFloorplanSelectorVisibility: floorplanSelectorVisible)

        reload()
    }

    func toggleWorkOrdersVisibility(_ sender: UIBarButtonItem) {
        toggleWorkOrdersVisibility()
    }

    func toggleWorkOrdersVisibility() {
        setWorkOrdersVisibility(!workOrdersVisible)
    }

    func setWorkOrdersVisibility(_ workOrdersVisible: Bool, alpha: CGFloat! = nil) {
        self.workOrdersVisible = workOrdersVisible
        if self.workOrdersVisible {
            navigatorVisible = false
            floorplanSelectorVisible = false
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

    func makeScaleVisible(_ scaleVisible: Bool) {
        self.scaleVisible = scaleVisible
        floorplanToolbarDelegate?.floorplanToolbar(self, shouldSetScaleVisibility: scaleVisible)

        reload()
    }

    func toggleScaleVisibility(_ sender: UIBarButtonItem) {
        toggleScaleVisibility()
    }

    func createWorkOrder(_ sender: UIBarButtonItem) {
        floorplanToolbarDelegate?.newWorkOrderShouldBeCreatedByFloorplanToolbar(self)

        reload()
    }

    func toggleFloorplanOptionsVisibility() {
        makeFloorplanOptionsVisible(!floorplanOptionsVisible)
    }

    func makeFloorplanOptionsVisible(_ floorplanOptionsVisible: Bool) {
        self.floorplanOptionsVisible = floorplanOptionsVisible
        floorplanToolbarDelegate?.floorplanToolbar(self, shouldSetFloorplanOptionsVisibility: floorplanOptionsVisible)

        reload()
    }

    func toggleFloorplanOptionsVisibility(_ sender: UIBarButtonItem) {
        toggleFloorplanOptionsVisibility()
    }

    func promptForSetScaleVisibility() {
        let preferredStyle: UIAlertControllerStyle = isIPad() ? .alert : .actionSheet
        let alertController = UIAlertController(title: "Scale has already been set. Do you really want to set it again?", message: nil, preferredStyle: preferredStyle)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        let setScaleAction = UIAlertAction(title: "Set Scale", style: .default) { action in
            self.scaleBeingEdited = true
            self.makeScaleVisible(true)
        }

        alertController.addAction(setScaleAction)

        floorplanToolbarDelegate?.floorplanToolbar(self, shouldPresentAlertController: alertController)
    }
}
