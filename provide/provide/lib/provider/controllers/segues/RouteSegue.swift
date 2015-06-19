//
//  RouteSegue.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class RouteSegue: UIStoryboardSegue {

    override func perform() {
        switch identifier! {
        case "RouteManifestViewControllerSegue":
            assert(sourceViewController is WorkOrdersViewController)
            assert(destinationViewController is RouteManifestViewController)
            (destinationViewController as! RouteManifestViewController).render()
        default:
            break
        }
    }

}
