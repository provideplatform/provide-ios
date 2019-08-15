//
//  MapView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import Foundation

class MapView: MKMapView {

    var defaultAnnotationViewReuseIdentifier = "defaultAnnotationViewReuseIdentifier"
    let userLocationAnnotationViewReuseIdentifier = "userLocationAnnotationViewReuseIdentifier"

    var requireUserLocationBeforeRevealing = false
    var updateUserLocationAnnotation = true

    private var shouldReveal: Bool {
        return !requireUserLocationBeforeRevealing || (alpha == 0 && mapFullyRenderedOnce && updatedUserLocationOnce)
    }

    private var mapFullyRenderedOnce = false
    private var updatedUserLocationOnce = false

    override func awakeFromNib() {
        super.awakeFromNib()

        delegate = self

        KTNotificationCenter.addObserver(forName: .ProfileImageShouldRefresh, queue: .main) { _ in
            self.updateUserLocationAnnotation = true
            self.showsUserLocation = false
            self.showsUserLocation = true
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

    var onMapRevealed: VoidBlock?

    func revealMap() {
        if shouldReveal {
            UIView.animate(withDuration: 0.25, animations: {
                self.alpha = 1
            }, completion: { finished in
                UIView.animate(withDuration: 0.25) {
                    self.onMapRevealed?()
                }
            })
        }
    }
}

// MARK: - MKMapViewDelegate
extension MapView: MKMapViewDelegate {

    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        if fullyRendered {
            mapFullyRenderedOnce = true

            revealMap()
        }
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        updatedUserLocationOnce = true
    }
}
