//
//  WorkOrdersMapView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

class WorkOrderMapView: MapView {

    var directionsViewControllerDelegate: DirectionsViewControllerDelegate! {
        didSet {
            LocationService.shared.resolveCurrentLocation { [weak self] location in
                guard let strongSelf = self else { return }
                strongSelf.mapViewDidUpdateUserLocation(strongSelf, location: location)
                LocationService.shared.background()
            }
        }
    }

    var workOrdersViewControllerDelegate: WorkOrdersViewControllerDelegate! {
        didSet {
            LocationService.shared.resolveCurrentLocation { [weak self] location in
                guard let strongSelf = self else { return }
                strongSelf.mapViewDidUpdateUserLocation(strongSelf, location: location)
                LocationService.shared.background()
            }
        }
    }

    private var userLocationImageView: UIImageView {
        let imageView: ProfileImageView

        if let profileImageUrl = currentUser.profileImageUrl {
            imageView = ProfileImageView(url: profileImageUrl)
        } else {
            imageView = ProfileImageView()
            // imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            // imageView.alpha = 0.0
            //  imageView.email = currentUser.email
            //  imageView.load { error in
            //      imageView.makeCircular()
            //      imageView.alpha = 1
            //  }
        }

        return imageView
    }

    private var viewingDirections: Bool {
        return directionsViewControllerDelegate?.isPresentingDirections() ?? false
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        defaultAnnotationViewReuseIdentifier = "workOrderAnnotationViewReuseIdentifier"
        requireUserLocationBeforeRevealing = true

        delegate = self

        showsBuildings = true
        showsPointsOfInterest = true

        LocationService.shared.requireAuthorization {
            self.showsUserLocation = true
            LocationService.shared.start()
        }
    }

    override func removeAnnotations() {
        var nonUserAnnotations = annotations
        if userLocation.location != nil {
            if let annotation = mapView(self, viewFor: userLocation) {
                nonUserAnnotations.removeObject(annotation)
            }
        }
        removeAnnotations(nonUserAnnotations)
    }

    func renderOverviewPolylineForWorkOrder(_ workOrder: WorkOrder) {
        DispatchQueue.main.async { [weak self] in
            if let overviewPolyline = workOrder.overviewPolyline {
                if let strongSelf = self {
                    if !strongSelf.overlays.contains(where: { overlay -> Bool in
                        if let overlay = overlay as? WorkOrder.OverviewPolyline {
                            return overlay.matches(overviewPolyline)
                        }
                        return false
                    }) {
                        strongSelf.add(overviewPolyline, level: .aboveRoads)
                        strongSelf.visibleMapRect = strongSelf.mapRectThatFits(overviewPolyline.boundingMapRect,
                                                                               edgePadding: UIEdgeInsets(top: 50.0, left: 20.0, bottom: 100.0, right: 20.0))
                    }
                }
            }
        }
    }

    // MARK: MKMapViewDelegate

    override func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        super.mapViewDidFinishRenderingMap(mapView, fullyRendered: true)
        if fullyRendered {
            if let mode = directionsViewControllerDelegate?.mapViewUserTrackingMode(mapView) {
                mapView.setUserTrackingMode(mode, animated: true)
            }
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view: MKAnnotationView?

        if annotation is MKUserLocation {
            view = mapView.dequeueReusableAnnotationView(withIdentifier: userLocationAnnotationViewReuseIdentifier)
            if view == nil || updateUserLocationAnnotation {
                updateUserLocationAnnotation = false

                let imageView = userLocationImageView

                if imageView.image == nil {
                    return nil // default blue location marker
                }

                view = MKAnnotationView(annotation: annotation, reuseIdentifier: userLocationAnnotationViewReuseIdentifier)
                view?.centerOffset = CGPoint(x: 0, y: (imageView.height / 2.0) * -1.0)
                view?.addSubview(imageView)
            }
        } else {
            view = mapView.dequeueReusableAnnotationView(withIdentifier: defaultAnnotationViewReuseIdentifier)
            if view == nil {
                view = workOrdersViewControllerDelegate?.annotationViewForMapView?(mapView, annotation: annotation)

                if view == nil && annotation is WorkOrder.Annotation {
                    let rect = CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0)
                    view = WorkOrderPinAnnotationView(frame: rect)
                }
            }
        }

        return view
    }

    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views {
            if view.annotation is MKUserLocation {
                view.isEnabled = false
            }
        }
    }

    override func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        super.mapView(mapView, didUpdate: userLocation)
        mapViewDidUpdateUserLocation(self, location: userLocation.location!)
    }

    func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: Error) {
        logWarn("MapView failed to locate user")
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
        logmoji("🗺", "Map view updated user location: \(location)")

        if mapView.alpha == 0 {
            logmoji("🗺", "Adjusting visible map rect based on location: \(location)")
            mapViewShouldRefreshVisibleMapRect(mapView)
            mapView.revealMap()

            if mapView.overlays.count == 0 {
                centerOnUserLocation()
            }
            //else if mapView.overlays.count == 1, let polyline = mapView.overlays.first as? MKPolyline {
            //    mapView.visibleMapRect = mapView.mapRectThatFits(polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 55.0, left: 25.0, bottom: 55.0, right: 25.0))
            //}
        }

        if !viewingDirections && WorkOrderService.shared.nextWorkOrder != nil {
            refreshEta(from: location.coordinate)
        } else if viewingDirections {
            centerOnUserLocation()
        }
    }

    func mapViewShouldRefreshVisibleMapRect(_ mapView: MKMapView, animated: Bool = false) {
        mapView.showAnnotations(mapView.annotations, animated: animated)
        //mapView.setVisibleMapRect(mapView.visibleMapRect, edgePadding: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), animated: animated)
    }

    func centerOnUserLocation() {
        setCenterCoordinate(userLocation.coordinate,
                            fromEyeCoordinate: centerCoordinate,
                            eyeAltitude: camera.altitude,
                            pitch: camera.pitch,
                            heading: camera.heading,
                            animated: false)
    }

    private func refreshEta(from coordinate: CLLocationCoordinate2D) {
        if let workOrdersViewControllerDelegate = workOrdersViewControllerDelegate {
            let onEtaFetched: (WorkOrder, Int) -> Void = { _, minutesEta in
                for vc in workOrdersViewControllerDelegate.managedViewControllersForViewController!(nil) {
                    (vc as? WorkOrdersViewControllerDelegate)?.drivingEtaToNextWorkOrderChanged?(minutesEta)
                }
            }

            if WorkOrderService.shared.nextWorkOrder != nil {
                WorkOrderService.shared.fetchNextWorkOrderDrivingEtaFromCoordinate(coordinate, onWorkOrderEtaFetched: onEtaFetched)
            } else if  WorkOrderService.shared.inProgressWorkOrder != nil {
                WorkOrderService.shared.fetchInProgressWorkOrderDrivingEtaFromCoordinate(coordinate, onWorkOrderEtaFetched: onEtaFetched)
            }
        }
    }
}
