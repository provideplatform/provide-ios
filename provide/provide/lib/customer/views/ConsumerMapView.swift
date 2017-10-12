//
//  ConsumerMapView.swift
//  provide
//
//  Created by Kyle Thomas on 8/22/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

class ConsumerMapView: MapView, UIGestureRecognizerDelegate {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

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
        if userLocation.location != nil {
            nonUserAnnotations.removeObject(mapView(self, viewFor: userLocation)!)
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

    // MARK: UIGestureRecognizerDelegate

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    // MARK: MKMapViewDelegate

    override func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        super.mapViewDidFinishRenderingMap(mapView, fullyRendered: true)
        if fullyRendered {
            logInfo("Consumer map view fully rendered")
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
                    // let icon = FAKFontAwesome.carIcon(withSize: 25.0)!
                    // let imageView = UIImageView(image: icon.image(with: CGSize(width: 25.0, height: 25.0)))
                    let icon = #imageLiteral(resourceName: "prvd-reg")
                    let imageView = UIImageView(image: icon)

                    view = MKAnnotationView(annotation: annotation, reuseIdentifier: defaultAnnotationViewReuseIdentifier)
                    view?.centerOffset = CGPoint(x: 0, y: (imageView.height / 2.0) * -1.0)
                    view?.addSubview(imageView)
                }
            }
        }

        return view
    }

    override func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        assert(self == mapView)
        super.mapView(mapView, didUpdate: userLocation)
        mapViewDidUpdateUserLocation(self, location: userLocation.location!)
    }

    func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: Error) {
         logWarn("MapView failed to locate user")
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer? {
        let renderer: MKOverlayRenderer? = nil

        logWarn("Returning nil overlay renderer for consumer map view; \(renderer!)")

        return renderer
    }

    func mapViewDidUpdateUserLocation(_ mapView: MapView, location: CLLocation) {
        log("Map view updated user location: \(location)")

        if mapView.alpha == 0 {
            log("Adjusting visible map rect based on location: \(location)")

            mapViewShouldRefreshVisibleMapRect(mapView)

            mapView.revealMap()
        }

        mapView.setCenterCoordinate(location.coordinate,
                                    fromEyeCoordinate: mapView.centerCoordinate,
                                    eyeAltitude: 20000.0,
                                    pitch: mapView.camera.pitch,
                                    heading: mapView.camera.heading,
                                    animated: false)
    }

    func mapViewDidFailToUpdateUserLocation(_ mapView: MapView, error: NSError) {
        logWarn("Map view failed to update user location")
    }

    func mapViewShouldRefreshVisibleMapRect(_ mapView: MKMapView, animated: Bool = false) {
        mapView.showAnnotations(mapView.annotations, animated: animated)
        mapView.setVisibleMapRect(mapView.visibleMapRect, edgePadding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), animated: animated)
    }
}
