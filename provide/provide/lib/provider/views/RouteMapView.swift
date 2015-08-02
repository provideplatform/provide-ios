//
//  RouteMapView.swift
//  provide
//
//  Created by Kyle Thomas on 8/2/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class RouteMapView: WorkOrderMapView {

    // MARK: MKMapViewDelegate

    override func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        var renderer: MKOverlayRenderer!

        if overlay is MKPolyline {
            let route = overlay as! MKPolyline
            renderer = MKPolylineRenderer(polyline: route)
            (renderer as! MKPolylineRenderer).strokeColor = Color.polylineStrokeColor()
            (renderer as! MKPolylineRenderer).lineWidth = 3.0
        }

        return renderer
    }
}
