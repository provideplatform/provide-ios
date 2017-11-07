//
//  ConsumerMapView.swift
//  provide
//
//  Created by Kyle Thomas on 8/22/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

class ConsumerMapView: MapView {

    override func awakeFromNib() {
        super.awakeFromNib()

        defaultAnnotationViewReuseIdentifier = "providerAnnotationViewReuseIdentifier"
        requireUserLocationBeforeRevealing = true

        delegate = self

        LocationService.shared.requireAuthorization {
            self.showsUserLocation = true
            LocationService.shared.start()
        }

        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(mapViewPinchGestureRecognized(_:)))
        pinchGestureRecognizer.delegate = self
        addGestureRecognizer(pinchGestureRecognizer)
    }

    override func removeAnnotations() {
        var nonUserAnnotations = annotations
        if let annotationView = mapView(self, viewFor: userLocation), userLocation.location != nil {
            nonUserAnnotations.removeObject(annotationView)
        }
        removeAnnotations(nonUserAnnotations)
    }

    @objc func mapViewPinchGestureRecognized(_ gesture: UIPinchGestureRecognizer) {
        for annotation in annotations where annotation is Provider.Annotation {
            if let annotationView = view(for: annotation) {
                for _ in annotationView.subviews {
                    // if v is UIImageView {
                    //     v.frame.size = CGSize(width: v.width * scale,
                    //                           height: v.height * scale)
                    // }
                }
            }
        }
    }

    func renderOverviewPolylineForWorkOrder(_ workOrder: WorkOrder) {
        DispatchQueue.main.async { [weak self] in
            if let overviewPolyline = workOrder.overviewPolyline {
                if let strongSelf = self {
                    strongSelf.add(overviewPolyline, level: .aboveRoads)
                    strongSelf.visibleMapRect = strongSelf.mapRectThatFits(overviewPolyline.boundingMapRect,
                                                                           edgePadding: UIEdgeInsets(top: 50.0, left: 20.0, bottom: 100.0, right: 20.0))
                }

            }
        }
    }

    // MARK: MKMapViewDelegate

    override func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        super.mapViewDidFinishRenderingMap(mapView, fullyRendered: true)
        if fullyRendered {
            logmoji("🗺", "Consumer map view fully rendered")
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view: MKAnnotationView?

        if annotation is MKUserLocation {
            view = mapView.dequeueReusableAnnotationView(withIdentifier: userLocationAnnotationViewReuseIdentifier)
            if view == nil || updateUserLocationAnnotation {
                return nil // default blue location marker
            }
        } else {
            view = mapView.dequeueReusableAnnotationView(withIdentifier: defaultAnnotationViewReuseIdentifier)
            if view == nil {
                if view == nil && annotation is Provider.Annotation {
                    if let icon = (annotation as! Provider.Annotation).icon {
                        let imageView = UIImageView(image: icon)

                        view = MKAnnotationView(annotation: annotation, reuseIdentifier: defaultAnnotationViewReuseIdentifier)
                        view?.centerOffset = CGPoint(x: 0, y: (imageView.height / 2.0) * -1.0)
                        view?.addSubview(imageView)
                    }
                }
            }
        }

        return view
    }

    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views {
            if view.annotation is MKUserLocation {
                view.isEnabled = false
            } else if let annotation = view.annotation as? Provider.Annotation {
                let rotationAngle = CGFloat(annotation.provider.lastCheckinHeading)
                view.transform = CGAffineTransform(rotationAngle: rotationAngle)
            }
        }
    }

    override func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        super.mapView(mapView, didUpdate: userLocation)
        mapViewDidUpdateUserLocation(self, location: userLocation.location!)
    }

    func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: Error) {
        logWarn("MapView failed to locate user: \(error.localizedDescription)")
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        var renderer: MKOverlayRenderer!

        if let route = overlay as? MKPolyline {
            renderer = MKPolylineRenderer(polyline: route)
            (renderer as! MKPolylineRenderer).fillColor = UIColor.black.withAlphaComponent(0.75)
            (renderer as! MKPolylineRenderer).strokeColor = .black
            (renderer as! MKPolylineRenderer).lineWidth = 1.8
        }

        return renderer
    }

    func mapViewDidUpdateUserLocation(_ mapView: MapView, location: CLLocation) {
        logmoji("🗺", "Consumer map view updated user location: \(location)")

        if mapView.alpha == 0 {
            logmoji("🗺", "Adjusting visible consumer map rect based on location: \(location)")
            mapView.showAnnotations(mapView.annotations, animated: false)
            mapView.revealMap()

            if mapView.overlays.count == 0 {
                centerOnUserLocation()
            } else if mapView.overlays.count == 1, let polyline = mapView.overlays.first as? MKPolyline {
                mapView.visibleMapRect = mapView.mapRectThatFits(polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 55.0, left: 25.0, bottom: 55.0, right: 25.0))
            }
        }
    }

    func centerOnUserLocation() {
        setCenterCoordinate(userLocation.coordinate,
                            fromEyeCoordinate: centerCoordinate,
                            eyeAltitude: 20000.0,
                            pitch: camera.pitch,
                            heading: camera.heading,
                            animated: false)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension ConsumerMapView: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
