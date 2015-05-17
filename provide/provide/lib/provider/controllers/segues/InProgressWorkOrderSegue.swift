//
//  InProgressWorkOrderSegue.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class InProgressWorkOrderSegue: UIStoryboardSegue {

    override func perform() {
        switch identifier! {
        case "DirectionsViewControllerSegue":
            assert(sourceViewController is WorkOrdersViewController)
            assert(destinationViewController is DirectionsViewController)
            (destinationViewController as! DirectionsViewController).render()
            break
        case "WorkOrderComponentViewControllerSegue":
            assert(sourceViewController is WorkOrdersViewController)
            assert(destinationViewController is WorkOrderComponentViewController)
            (destinationViewController as! WorkOrderComponentViewController).render()
            break
        default:
            break
        }
    }

}
