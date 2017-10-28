//
//  RenderComponentStoryboardSegue.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class RenderComponentStoryboardSegue: UIStoryboardSegue {

    override func perform() {
        switch identifier! {
        case "DirectionsViewControllerSegue":
            assert(source is WorkOrdersViewController && destination is DirectionsViewController)
            (destination as! DirectionsViewController).render()
        case "WorkOrderAnnotationViewControllerSegue":
            assert(source is WorkOrdersViewController && destination is WorkOrderAnnotationViewController)
            (destination as! WorkOrderAnnotationViewController).render()
            (destination as! WorkOrderAnnotationViewController).onConfirmationRequired = {
                self.destination.performSegue(withIdentifier: "WorkOrderAnnotationViewTouchedUpInsideSegue", sender: self.source)
            }
            if let mapView = (source as! WorkOrdersViewControllerDelegate).mapViewForViewController?(source as! ViewController) {
                mapView.mapViewShouldRefreshVisibleMapRect(mapView, animated: true)
            }
        case "WorkOrderAnnotationViewTouchedUpInsideSegue":
            assert(source is WorkOrderAnnotationViewController && destination is WorkOrdersViewController)
            source.performSegue(withIdentifier: "WorkOrderAnnotationViewControllerUnwindSegue", sender: self)
        case "WorkOrderDestinationHeaderViewControllerSegue":
            assert(source is WorkOrdersViewController && destination is WorkOrderDestinationHeaderViewController)
            (destination as! WorkOrderDestinationHeaderViewController).render()
        case "WorkOrderDestinationConfirmationViewControllerSegue":
            assert(source is WorkOrdersViewController && destination is WorkOrderDestinationConfirmationViewController)
            let destinationConfirmationViewController = destination as! WorkOrderDestinationConfirmationViewController
            destinationConfirmationViewController.render()
            destinationConfirmationViewController.configure(onConfirm: {
                var workOrdersViewControllerDelegate: WorkOrdersViewControllerDelegate?
                if let delegate = destinationConfirmationViewController.workOrdersViewControllerDelegate {
                    workOrdersViewControllerDelegate = delegate
                    for vc in delegate.managedViewControllersForViewController!(destinationConfirmationViewController) where vc != destinationConfirmationViewController {
                        delegate.nextWorkOrderContextShouldBeRewoundForViewController?(vc)
                    }
                }

                destinationConfirmationViewController.showProgressIndicator()
                workOrdersViewControllerDelegate?.confirmationReceivedForWorkOrderViewController?(destinationConfirmationViewController)
            })
        default:
            break
        }
    }
}
