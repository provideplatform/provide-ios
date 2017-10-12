//
//  MapView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

class MapView: MKMapView, MKMapViewDelegate {

    var defaultAnnotationViewReuseIdentifier = "defaultAnnotationViewReuseIdentifier"
    let userLocationAnnotationViewReuseIdentifier = "userLocationAnnotationViewReuseIdentifier"

    var requireUserLocationBeforeRevealing = false
    var updateUserLocationAnnotation = true

    private var shouldReveal: Bool {
        return !requireUserLocationBeforeRevealing || (alpha == 0 && mapFullyRenderedOnce && updatedUserLocationOnce)
    }

    private var mapFullyRenderedOnce = false
    private var updatedUserLocationOnce = false

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        delegate = self

        NotificationCenter.default.addObserverForName("ProfileImageShouldRefresh") { _ in
            self.updateUserLocationAnnotation = true
            self.showsUserLocation = false
            DispatchQueue.main.async {
                self.showsUserLocation = true
            }
        }
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

    func revealMap(_ force: Bool = false) {
        revealMap(force, animations: {
            self.alpha = 1
        })
    }

    var onMapRevealed: VoidBlock?

    func revealMap(_ force: Bool, animations: @escaping VoidBlock, completion: VoidBlock? = nil) {
        if shouldReveal || force {
            UIView.animate(withDuration: 0.25, animations: animations, completion: { finished in
                completion?()
                UIView.animate(withDuration: 0.25) {
                    self.onMapRevealed?()
                }
            })
        }
    }

    // MARK: MKMapViewDelegate

    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        if fullyRendered {
            mapFullyRenderedOnce = true

            revealMap()
        }
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        updatedUserLocationOnce = true
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
