//
//  NextWorkOrderUnwindSegue.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class NextWorkOrderUnwindSegue: UIStoryboardSegue {

    override func perform() {
        switch identifier! {
        case "WorkOrderAnnotationViewControllerUnwindSegue":
            assert(sourceViewController is WorkOrderAnnotationViewController)
            assert(destinationViewController is WorkOrdersViewController)
            break
        case "WorkOrderDestinationHeaderViewControllerUnwindSegue":
            assert(sourceViewController is WorkOrderDestinationHeaderViewController)
            assert(destinationViewController is WorkOrdersViewController)
            break
        case "WorkOrderDestinationConfirmationViewControllerUnwindSegue":
            assert(sourceViewController is WorkOrderDestinationConfirmationViewController)
            assert(destinationViewController is WorkOrdersViewController)
            break
        default:
            break
        }
    }
    
}
