//
//  WorkOrdersMapView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import KTSwiftExtensions

class WorkOrderMapView: MapView {

    var directionsViewControllerDelegate: DirectionsViewControllerDelegate! {
        didSet {
            LocationService.sharedService().resolveCurrentLocation { [weak self] location in
                if let strongSelf = self {
                    strongSelf.mapViewDidUpdateUserLocation(strongSelf, location: location)
                    LocationService.sharedService().background()
                }
            }
        }
    }

    var workOrdersViewControllerDelegate: WorkOrdersViewControllerDelegate! {
        didSet {
            LocationService.sharedService().resolveCurrentLocation { [weak self] location in
                if let strongSelf = self {
                    strongSelf.mapViewDidUpdateUserLocation(strongSelf, location: location)
                    LocationService.sharedService().background()
                }
            }
        }
    }

    fileprivate var userLocationImageView: UIImageView {
        let imageView: UIImageView

        if let profileImageUrl = currentUser.profileImageUrl {
            imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            imageView.contentMode = .scaleAspectFit
            imageView.alpha = 0.0
            imageView.sd_setImage(with: profileImageUrl as URL) { image, error, cacheType, url in
                imageView.makeCircular()
                imageView.alpha = 1
            }
        } else {
            imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            imageView.alpha = 0.0
//            imageView.email = currentUser.email
//            imageView.load { error in
//                imageView.makeCircular()
//                imageView.alpha = 1
//            }
        }

        return imageView
    }

    fileprivate var viewingDirections: Bool {
        if let delegate = directionsViewControllerDelegate {
            return delegate.isPresentingDirections()
        }
        return false
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        defaultAnnotationViewReuseIdentifier = "workOrderAnnotationViewReuseIdentifier"
        requireUserLocationBeforeRevealing = true

        delegate = self

        showsBuildings = true
        showsPointsOfInterest = true

        LocationService.sharedService().requireAuthorization {
            self.showsUserLocation = true
            LocationService.sharedService().start()
        }
    }

    override func removeAnnotations() {
        var nonUserAnnotations = annotations
        if userLocation.location != nil {
            nonUserAnnotations.removeObject(mapView(self, viewForAnnotation: userLocation)!)
        }
        removeAnnotations(nonUserAnnotations)
    }

    override func revealMap(_ force: Bool = false) {
        super.revealMap(force,
            animations: {
                self.alpha = 1
            },
            completion: nil
        )
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

    func mapView(_ mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var view: MKAnnotationView?

        if annotation is MKUserLocation {
            view = mapView.dequeueReusableAnnotationView(withIdentifier: userLocationAnnotationViewReuseIdentifier)
            if view == nil || updateUserLocationAnnotation {
                updateUserLocationAnnotation = false

                let imageView = userLocationImageView

                view = MKAnnotationView(annotation: annotation, reuseIdentifier: userLocationAnnotationViewReuseIdentifier)
                view?.centerOffset = CGPoint(x: 0, y: (imageView.bounds.height / 2.0) * -1.0);
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

    func mapViewWillStartLocatingUser(_ mapView: MKMapView) {
    }

    override func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        assert(self == mapView)
        super.mapView(mapView, didUpdate: userLocation)
        mapViewDidUpdateUserLocation(self, location: userLocation.location!)
    }

    func mapViewDidStopLocatingUser(_ mapView: MKMapView) {
    }

    func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: NSError) {
        logWarn("MapView failed to locate user")
    }

    func mapView(_ mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer! {
        var renderer: MKOverlayRenderer!

        if let route = overlay as? MKPolyline {
            renderer = MKPolylineRenderer(polyline: route)
            (renderer as! MKPolylineRenderer).strokeColor = Color.polylineStrokeColor()
            //(renderer as! MKPolylineRenderer).lineWidth = 3.0
        }

        return renderer
    }

    func mapView(_ mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {

    }

    func mapViewDidUpdateUserLocation(_ mapView: MapView, location: CLLocation) {
        log("Map view updated user location: \(location)")

        if mapView.alpha == 0 {
            log("Adjusting visible map rect based on location: \(location)")

            mapViewShouldRefreshVisibleMapRect(mapView)

            mapView.revealMap(false,
                animations: {
                    log("Revealing map rect based on location: \(location)")
                    mapView.alpha = 1
                },
                completion: nil
            )
        }

        if !viewingDirections && WorkOrderService.sharedService().nextWorkOrder != nil {
            if workOrdersViewControllerDelegate != nil {
                WorkOrderService.sharedService().fetchNextWorkOrderDrivingEtaFromCoordinate(location.coordinate) { workOrder, minutesEta in
                    for vc in self.workOrdersViewControllerDelegate.managedViewControllersForViewController!(nil) {
                        if let delegate = vc as? WorkOrdersViewControllerDelegate {
                            delegate.drivingEtaToNextWorkOrderChanged?(minutesEta as NSNumber)
                        }
                    }
                }
            }
        } else if viewingDirections {
            mapView.setCenterCoordinate(location.coordinate,
                fromEyeCoordinate: mapView.centerCoordinate,
                eyeAltitude: mapView.camera.altitude,
                pitch: mapView.camera.pitch,
                heading: mapView.camera.heading,
                animated: false)
        }
    }

    func mapViewDidFailToUpdateUserLocation(_ mapView: MapView, error: NSError) {
        logWarn("Map view failed to update user location")
    }

    func mapViewShouldRefreshVisibleMapRect(_ mapView: MKMapView, animated: Bool = false) {
        mapView.showAnnotations(mapView.annotations, animated: animated)
        mapView.setVisibleMapRect(mapView.visibleMapRect, edgePadding: UIEdgeInsetsMake(0, 0, 0, 0), animated: animated)
    }
}
