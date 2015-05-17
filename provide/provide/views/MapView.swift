//
//  MapView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class MapView: MKMapView, MKMapViewDelegate {

    var defaultAnnotationViewReuseIdentifier = "defaultAnnotationViewReuseIdentifier"
    var userLocationAnnotationViewReuseIdentifier = "userLocationAnnotationViewReuseIdentifier"

    var requireUserLocationBeforeRevealing = false

    private var shouldReveal: Bool {
        return requireUserLocationBeforeRevealing == false || (alpha == 0 && mapFullyRenderedOnce == true && updatedUserLocationOnce == true)
    }

    private var mapFullyRenderedOnce = false
    private var updatedUserLocationOnce = false

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        delegate = self
    }

    func removeAnnotations() {
        var annotations = NSMutableArray(array: self.annotations)
        if let location = userLocation {
            annotations.removeObject(location)
        }
        removeAnnotations(annotations as [AnyObject])
    }

    func removeOverlays() {
        removeOverlays(overlays)
    }

    func revealMap(force: Bool = false) {
        revealMap(force, animations: { () -> Void in
            self.alpha = 1
        }, completion: nil)
    }

    func revealMap(force: Bool, animations: VoidBlock!, completion: VoidBlock!) {
        if shouldReveal == true || force == true {
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                if animations != nil {
                    animations()
                }
            }, completion: { (finished: Bool) -> Void in
                if completion != nil {
                    completion()
                }
            })
        }
    }

    // MARK: MKMapViewDelegate

    func mapViewDidFinishRenderingMap(mapView: MKMapView!, fullyRendered: Bool) {
        if fullyRendered == true {
            mapFullyRenderedOnce = true

            revealMap()
        }
    }

    func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!) {
        updatedUserLocationOnce = true
    }

}
