//
//  RenderComponentSegue.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class RenderComponentSegue: UIStoryboardSegue {

    override func perform() {
        switch identifier! {
        case "DirectionsViewControllerSegue":
            assert(sourceViewController is WorkOrdersViewController)
            assert(destinationViewController is DirectionsViewController)
            (destinationViewController as! DirectionsViewController).render()
        case "WorkOrderAnnotationViewControllerSegue":
            assert(sourceViewController is WorkOrdersViewController)
            assert(destinationViewController is WorkOrderAnnotationViewController)
            (destinationViewController as! WorkOrderAnnotationViewController).render()
            (destinationViewController as! WorkOrderAnnotationViewController).onConfirmationRequired = { () -> () in
                self.destinationViewController.performSegueWithIdentifier("WorkOrderAnnotationViewTouchedUpInsideSegue", sender: self.sourceViewController)
            }
            if let mapView = (sourceViewController as! WorkOrdersViewControllerDelegate).mapViewForViewController?(sourceViewController as! ViewController) {
                mapView.mapViewShouldRefreshVisibleMapRect(mapView, animated: true)
            }
        case "WorkOrderAnnotationViewTouchedUpInsideSegue":
            assert(sourceViewController is WorkOrderAnnotationViewController)
            assert(destinationViewController is WorkOrdersViewController)
            sourceViewController.performSegueWithIdentifier("WorkOrderAnnotationViewControllerUnwindSegue", sender: self)
        case "WorkOrderComponentViewControllerSegue":
            assert(sourceViewController is WorkOrdersViewController)
            assert(destinationViewController is WorkOrderComponentViewController)
            (destinationViewController as! WorkOrderComponentViewController).render()
        case "WorkOrderDestinationHeaderViewControllerSegue":
            assert(sourceViewController is WorkOrdersViewController)
            assert(destinationViewController is WorkOrderDestinationHeaderViewController)
            (destinationViewController as! WorkOrderDestinationHeaderViewController).render()
        case "WorkOrderDestinationConfirmationViewControllerSegue":
            assert(sourceViewController is WorkOrdersViewController)
            assert(destinationViewController is WorkOrderDestinationConfirmationViewController)

            let destinationConfirmationViewController = destinationViewController as! WorkOrderDestinationConfirmationViewController
            destinationConfirmationViewController.render()
            destinationConfirmationViewController.onConfirmationReceived = { () -> () in
                let delegate = destinationConfirmationViewController.workOrdersViewControllerDelegate
                for vc in delegate.managedViewControllersForViewController!(destinationConfirmationViewController) {
                    if vc != destinationConfirmationViewController {
                        delegate.nextWorkOrderContextShouldBeRewoundForViewController?(vc)
                    }
                }

                destinationConfirmationViewController.showProgressIndicator()

                delegate.confirmationReceivedForWorkOrderViewController?(destinationConfirmationViewController)
            }
        default:
            break
        }
    }
}
