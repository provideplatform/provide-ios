//
//  InProgressWorkOrderUnwindSegue.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class InProgressWorkOrderUnwindSegue: UIStoryboardSegue {

    override func perform() {
        switch identifier! {
        case "DirectionsViewControllerUnwindSegue":
            assert(sourceViewController is DirectionsViewController)
            assert(destinationViewController is WorkOrdersViewController)
            break
        case "WorkOrderComponentViewControllerUnwindSegue":
            assert(sourceViewController is WorkOrderComponentViewController)
            assert(destinationViewController is WorkOrdersViewController)
            break
        default:
            break
        }
    }

}
