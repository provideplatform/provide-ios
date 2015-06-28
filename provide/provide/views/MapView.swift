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
    let userLocationAnnotationViewReuseIdentifier = "userLocationAnnotationViewReuseIdentifier"

    var requireUserLocationBeforeRevealing = false

    private var shouldReveal: Bool {
        return !requireUserLocationBeforeRevealing || (alpha == 0 && mapFullyRenderedOnce && updatedUserLocationOnce)
    }

    private var mapFullyRenderedOnce = false
    private var updatedUserLocationOnce = false

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        delegate = self
    }

    func removeAnnotations() {
        var nonUserAnnotations = annotations
        if userLocation.location != nil {
            nonUserAnnotations.removeObject(userLocation)
        }
        removeAnnotations(nonUserAnnotations)
    }

    func removeOverlays() {
        removeOverlays(overlays)
    }

    func revealMap(force: Bool = false) {
        revealMap(force,
            animations: {
                self.alpha = 1
            },
            completion: nil
        )
    }

    func revealMap(force: Bool, animations: VoidBlock, completion: VoidBlock?) {
        if shouldReveal || force {
            UIView.animateWithDuration(0.25,
                animations: animations,
                completion: { finished in
                    completion?()
                }
            )
        }
    }

    // MARK: MKMapViewDelegate

    func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        if fullyRendered {
            mapFullyRenderedOnce = true

            revealMap()
        }
    }

    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation) {
        updatedUserLocationOnce = true
    }
}
