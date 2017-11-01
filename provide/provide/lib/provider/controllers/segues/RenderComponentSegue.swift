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
            assert(source is WorkOrdersViewController)
            (destination as! DirectionsViewController).render()
        case "WorkOrderAnnotationViewControllerSegue":
            assert(source is WorkOrdersViewController)
            (destination as! WorkOrderAnnotationViewController).render()
        case "WorkOrderAnnotationViewTouchedUpInsideSegue":
            assert(source is WorkOrderAnnotationViewController && destination is WorkOrdersViewController)
            source.performSegue(withIdentifier: "WorkOrderAnnotationViewControllerUnwindSegue", sender: self)
        case "WorkOrderDestinationConfirmationViewControllerSegue":
            assert(source is WorkOrdersViewController)
            let destinationConfirmationViewController = destination as! WorkOrderDestinationConfirmationViewController
            destinationConfirmationViewController.render()
        default:
            break
        }
    }
}
