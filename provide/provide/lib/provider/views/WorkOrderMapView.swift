//
//  WorkOrdersMapView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class WorkOrderMapView: MapView, MKMapViewDelegate {

    var directionsViewControllerDelegate: DirectionsViewControllerDelegate! {
        didSet {
            LocationService.sharedService().resolveCurrentLocation { [weak self] location in
                self!.mapViewDidUpdateUserLocation(self, location: location)
                LocationService.sharedService().background()
            }
        }
    }

    var workOrdersViewControllerDelegate: WorkOrdersViewControllerDelegate! {
        didSet {
            LocationService.sharedService().resolveCurrentLocation { [weak self] location in
                self!.mapViewDidUpdateUserLocation(self, location: location)
                LocationService.sharedService().background()
            }
        }
    }

    private var userLocationImageView: UIImageView! {
        var imageView: UIImageView!

        if let user = KeyChainService.sharedService().token?.user {
            if user.profileImageUrl != nil {
                imageView = UIImageView(frame: CGRectMake(0, 0, 50, 50))
                imageView.contentMode = .ScaleAspectFit
                imageView.alpha = 0.0
                imageView.sd_setImageWithURL(NSURL(string: user.profileImageUrl)) { image, error, cacheType, url in
                    imageView.makeCircular()
                    imageView.alpha = 1
                }
            } else {
                imageView = RFGravatarImageView(frame: CGRectMake(0, 0, 50, 50))
                imageView.alpha = 0.0
                (imageView as! RFGravatarImageView).email = user.email
                (imageView as! RFGravatarImageView).load { error in
                    imageView.makeCircular()
                    imageView.alpha = 1
                }
            }
        }

        return imageView
    }

    private var viewingDirections: Bool {
        if let delegate = directionsViewControllerDelegate {
            return delegate.isPresentingDirections()
        }
        return false
    }

    required init(coder aDecoder: NSCoder) {
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
        var annotations = NSMutableArray(array: self.annotations)
        if let location = userLocation {
            annotations.removeObject(mapView(self, viewForAnnotation: userLocation))
        }
        removeAnnotations(annotations as [AnyObject])
    }

    override func revealMap(force: Bool = false) {
        super.revealMap(force,
            animations: {
                self.alpha = 1
            },
            completion: {

            }
        )
    }

    // MARK: MKMapViewDelegate

    override func mapViewDidFinishRenderingMap(mapView: MKMapView!, fullyRendered: Bool) {
        super.mapViewDidFinishRenderingMap(mapView, fullyRendered: true)
        if fullyRendered {
            if let mode = directionsViewControllerDelegate?.mapViewUserTrackingMode?(mapView) {
                mapView.setUserTrackingMode(mode, animated: true)
            }
        }
    }

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        var view: MKAnnotationView?

        if annotation is MKUserLocation {
            view = mapView.dequeueReusableAnnotationViewWithIdentifier(userLocationAnnotationViewReuseIdentifier)
            if view == nil {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: userLocationAnnotationViewReuseIdentifier)
                view?.addSubview(userLocationImageView)
            }
        } else {
            view = mapView.dequeueReusableAnnotationViewWithIdentifier(defaultAnnotationViewReuseIdentifier)
            if view == nil {
                view = workOrdersViewControllerDelegate?.annotationViewForMapView?(mapView, annotation: annotation)
            }
        }

        return view
    }

    func mapViewWillStartLocatingUser(mapView: MKMapView!) {
    }

    override func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!) {
        assert(self == mapView)
        super.mapView(mapView, didUpdateUserLocation: userLocation)
        mapViewDidUpdateUserLocation(self, location: userLocation.location)
    }

    func mapViewDidStopLocatingUser(mapView: MKMapView!) {
    }

    func mapView(mapView: MKMapView!, didFailToLocateUserWithError error: NSError!) {
        logWarn("MapView failed to locate user")
    }

    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        var renderer: MKOverlayRenderer!

        if overlay! is MKPolyline {
            let route = overlay as! MKPolyline
            renderer = MKPolylineRenderer(polyline: route)
            (renderer as! MKPolylineRenderer).strokeColor = UIColor.blueColor()
            //(renderer as! MKPolylineRenderer).lineWidth = 3.0
        }

        return renderer
    }

    func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!) {

    }

    func mapViewDidUpdateUserLocation(mapView: MapView!, location: CLLocation!) {
        log("Map view updated user location: \(location)")

        if mapView.alpha == 0 {
            log("Adjusting visible map rect based on location: \(location)")

            mapViewShouldRefreshVisibleMapRect(mapView)

            mapView.revealMap(false,
                animations: {
                    log("Revealing map rect based on location: \(location)")
                    mapView.alpha = 1
                },
                completion: {

                }
            )
        }

        if let token = KeyChainService.sharedService().token { // HACK this is temporary
            if viewingDirections == false && WorkOrderService.sharedService().nextWorkOrder != nil {
                if workOrdersViewControllerDelegate != nil {
                    WorkOrderService.sharedService().fetchNextWorkOrderDrivingEtaFromCoordinate(location.coordinate) { workOrder, minutesEta in
                        for vc in self.workOrdersViewControllerDelegate.managedViewControllersForViewController!(nil) {
                            if vc is WorkOrdersViewControllerDelegate {
                                (vc as! WorkOrdersViewControllerDelegate).drivingEtaToNextWorkOrderChanged?(minutesEta as NSNumber)
                            }
                        }
                    }
                }
            }
        } else {
            mapView.showsUserLocation = false
        }
    }

    func mapViewDidFailToUpdateUserLocation(mapView: MapView!, error: NSError!) {
        logWarn("Map view failed to update user location")
    }

    func mapViewShouldRefreshVisibleMapRect(mapView: MKMapView!, animated: Bool = false) {
        mapView.showAnnotations(mapView.annotations, animated: animated)
        mapView.setVisibleMapRect(mapView.visibleMapRect, edgePadding: UIEdgeInsetsMake(0, 0, 0, 0), animated: animated)
    }

    //    // mapView:didAddAnnotationViews: is called after the annotation views have been added and positioned in the map.
    //    // The delegate can implement this method to animate the adding of the annotations views.
    //    // Use the current positions of the annotation views as the destinations of the animation.
    //    optional func mapView(mapView: MKMapView!, didAddAnnotationViews views: [AnyObject]!)
    //
    //    // mapView:annotationView:calloutAccessoryControlTapped: is called when the user taps on left & right callout accessory UIControls.
    //    optional func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!)
    //
    //    @availability(iOS, introduced=4.0)
    //    optional func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!)
    //    @availability(iOS, introduced=4.0)
    //    optional func mapView(mapView: MKMapView!, didDeselectAnnotationView view: MKAnnotationView!)
    //
    //    @availability(iOS, introduced=4.0)
    //
    //    @availability(iOS, introduced=4.0)
    //    optional func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState)
    //
    //    @availability(iOS, introduced=5.0)
    //    optional func mapView(mapView: MKMapView!, didChangeUserTrackingMode mode: MKUserTrackingMode, animated: Bool)
    //
    //    @availability(iOS, introduced=7.0)

    //    @availability(iOS, introduced=7.0)
    //    optional func mapView(mapView: MKMapView!, didAddOverlayRenderers renderers: [AnyObject]!)

}
