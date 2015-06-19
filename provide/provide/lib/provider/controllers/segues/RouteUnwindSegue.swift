//
//  RouteUnwindSegue.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class RouteUnwindSegue: UIStoryboardSegue {

    override func perform() {
        switch identifier! {
        case "RouteManifestViewControllerUnwindSegue":
            assert(sourceViewController is RouteManifestViewController)
            assert(destinationViewController is WorkOrdersViewController)
        default:
            break
        }
    }

}
