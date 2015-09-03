//
//  DirectionsViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

protocol DirectionsViewControllerDelegate {
    func isPresentingDirections() -> Bool
    func finalDestinationForDirectionsViewController(directionsViewController: DirectionsViewController) -> CLLocationCoordinate2D
    func mapViewForDirectionsViewController(directionsViewController: DirectionsViewController) -> MKMapView!
    func navbarPromptForDirectionsViewController(viewController: UIViewController) -> String!
    func navigationControllerForViewController(viewController: UIViewController) -> UINavigationController!
    func navigationControllerNavigationItemForViewController(viewController: UIViewController) -> UINavigationItem!
    func mapViewUserTrackingMode(mapView: MKMapView) -> MKUserTrackingMode
    func targetViewForViewController(viewController: UIViewController) -> UIView
}

class DirectionsViewController: ViewController {

    private let defaultMapCameraPitch = 0.0 //65.0
    private let defaultMapCameraAltitude = 500.0

    private let defaultLocationResolvedDurableCallbackKey = "directionsLocationDurableCallback"
    private let defaultHeadingResolvedDurableCallbackKey = "directionsHeadingDurableCallback"

    private var regions: [CLCircularRegion]!
    private var lastRegionCrossed: CLCircularRegion!
    private var lastRegionCrossing: NSDate!

    @IBOutlet private weak var directionsInstructionView: DirectionsInstructionView!

    var directions: Directions? {
        didSet {
            if directions == nil {
                showProgressIndicator()

                unregisterMonitoredRegions()
                regions = [CLCircularRegion]()
                lastRegionCrossing = nil
            } else {
                hideProgressIndicator()

                resolveCurrentStep()
                refreshInstructions()
                renderRouteOverview()

                if let navigationItem = directionsViewControllerDelegate?.navigationControllerNavigationItemForViewController(self) {
                    if let prompt =  directionsViewControllerDelegate?.navbarPromptForDirectionsViewController(self) {
                        navigationItem.prompt = prompt
                    } else {
                        navigationItem.prompt = nil
                    }
                }
            }
        }
    }

    private func resolveCurrentStep() { // FIXME -- move this to the route model
        if let leg = directions?.selectedRoute?.currentLeg {
            if let nextStep = leg.nextStep {
                leg.currentStep.instruction = nextStep.instruction
                leg.currentStep.maneuver = nextStep.maneuver
            }
        }
    }

    var directionsViewControllerDelegate: DirectionsViewControllerDelegate!

    private var targetView: UIView {
        return directionsViewControllerDelegate.targetViewForViewController(self)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: Rendering

    func render() {
        if let mapView = directionsViewControllerDelegate.mapViewForDirectionsViewController(self) {
            if let mapView = mapView as? WorkOrderMapView {
                if let inProgressWorkOrder = WorkOrderService.sharedService().inProgressWorkOrder {
                    mapView.addAnnotation(inProgressWorkOrder)
                }

                mapView.disableUserInteraction()

                mapView.setCenterCoordinate(mapView.userLocation.coordinate,
                                            fromEyeCoordinate: mapView.userLocation.coordinate,
                                            eyeAltitude: defaultMapCameraAltitude,
                                            pitch: CGFloat(defaultMapCameraPitch),
                                            animated: true)

                mapView.directionsViewControllerDelegate = directionsViewControllerDelegate
            }
        }

        let frame = CGRect(
            x: 0.0,
            y: targetView.frame.height,
            width: targetView.frame.width,
            height: view.frame.height)

        view.alpha = 0.0
        view.frame = frame

        targetView.addSubview(view)

        directionsInstructionView.frame = CGRect(
            x: directionsInstructionView.frame.origin.x,
            y: directionsInstructionView.frame.origin.y,
            width: targetView.frame.width,
            height: directionsInstructionView.frame.height)

        directionsInstructionView.routeLeg = nil
        refreshInstructions()

        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: {
                self.view.alpha = 1
                self.view.frame = CGRect(
                    x: frame.origin.x,
                    y: frame.origin.y - self.view.frame.height,
                    width: frame.width,
                    height: frame.height
                )
            },
            completion: { complete in
                LocationService.sharedService().resolveCurrentLocation(self.defaultLocationResolvedDurableCallbackKey, allowCachedLocation: false) { location in
                    if let _ = self.directions {
                        self.setCenterCoordinate(location)
                    }

                    if let lastRegionCrossing = self.lastRegionCrossing {
                        if abs(lastRegionCrossing.timeIntervalSinceNow) >= 5.0 && self.lastRegionCrossed != nil && !self.lastRegionCrossed.containsCoordinate(location.coordinate) {
                            self.directions = nil
                        }
                    }

                    if self.directions == nil {
                        self.regions = [CLCircularRegion]()
                        self.lastRegionCrossing = nil
                        self.lastRegionCrossed = nil

                        self.fetchDrivingDirections(location)
                    } else {
                        if let lastRegionCrossing = self.lastRegionCrossing {
                            if abs(lastRegionCrossing.timeIntervalSinceNow) >= 5.0 && self.lastRegionCrossed != nil && !self.lastRegionCrossed.containsCoordinate(location.coordinate) {
                                self.directions = nil
                            }
                        } else {
                            self.fetchDrivingDirections(location)
                        }
                    }
                }
            }
        )
    }

    private func setCenterCoordinate(location: CLLocation) {
        if let mapView = directionsViewControllerDelegate.mapViewForDirectionsViewController(self) {
            var sufficientDelta = false
            if let lastLocation = LocationService.sharedService().currentLocation {
                let lastCoordinate = lastLocation.coordinate
                let region = CLCircularRegion(center: lastCoordinate, radius: 2.5, identifier: "sufficientDeltaRegionMonitor")
                sufficientDelta = !region.containsCoordinate(location.coordinate)
            } else {
                sufficientDelta = true
            }

            if sufficientDelta {
                if let directions = directions {
                    let distance = MKMetersBetweenMapPoints(MKMapPointForCoordinate(location.coordinate),
                        MKMapPointForCoordinate(directions.selectedRoute.currentLeg.currentStep.startCoordinate))

                    let cameraAltitude = distance / tan(M_PI*(15 / 180.0))

                    mapView.setCenterCoordinate(location.coordinate, //directions.selectedRoute.currentLeg.currentStep.endCoordinate, //location.coordinate,
                        fromEyeCoordinate: directions.selectedRoute.currentLeg.currentStep.startCoordinate,
                        eyeAltitude: cameraAltitude,
                        heading: calculateBearing(directions.selectedRoute.currentLeg.currentStep.startCoordinate),
                        pitch: CGFloat(defaultMapCameraPitch),
                        animated: false)
                }
            }
        }
    }

    private func fetchDrivingDirections(location: CLLocation!) {
        let callback: OnDrivingDirectionsFetched = { directions in
            self.directions = directions

            self.setCenterCoordinate(location)

            for leg in directions.selectedRoute.legs {
                for step in [leg.currentStep] {
                    for coordinate in step.shapeCoordinates {
                        let overlay = MKCircle(centerCoordinate: coordinate, radius: 5.0)
                        let identifier = step.identifier + "_\(coordinate.latitude),\(coordinate.longitude)"
                        let region = CLCircularRegion(center: overlay.coordinate, radius: overlay.radius, identifier: identifier)

                        self.regions.append(region)

                        LocationService.sharedService().monitorRegion(region,
                            onDidEnterRegion: {
                                self.lastRegionCrossed = region
                                self.lastRegionCrossing = NSDate()

                                self.regions.removeObject(region)
                                LocationService.sharedService().unregisterRegionMonitor(region.identifier)

                                if let directions = self.directions {
                                    if let currentLeg = directions.selectedRoute.currentLeg {
                                        if let currentStep = currentLeg.currentStep {
                                            var identifier = ""
                                            if let currentShapeCoordinate = currentStep.currentShapeCoordinate {
                                                if let currentStepIdentifier = currentStep.identifier {
                                                    identifier = currentStepIdentifier + "_\(currentShapeCoordinate.latitude),\(currentShapeCoordinate.longitude)"
                                                }
                                            }

                                            if self.lastRegionCrossed.identifier == identifier {
                                                currentStep.currentShapeIndex += 1

                                                if currentStep.isFinished {
                                                    currentLeg.currentStepIndex += 1
                                                }
                                            } else if self.lastRegionCrossed.center.latitude == currentStep.endCoordinate.latitude && self.lastRegionCrossed.center.longitude == currentStep.endCoordinate.longitude {
                                                currentLeg.currentStepIndex += 1
                                            } else {
                                                var shapeIndex = currentStep.shape.count - 1
                                                for shapeCoord in Array(currentStep.shapeCoordinates.reverse()) {
                                                    if self.lastRegionCrossed.center.latitude == shapeCoord.latitude && self.lastRegionCrossed.center.longitude == shapeCoord.longitude {
                                                        currentStep.currentShapeIndex = shapeIndex
                                                        if currentStep.isFinished {
                                                            currentLeg.currentStepIndex += 1
                                                        }
                                                        break
                                                    }
                                                    shapeIndex -= 1
                                                }
                                            }

                                            dispatch_after_delay(0.0) {
                                                self.resolveCurrentStep()
                                                self.refreshInstructions()
                                                self.renderRouteOverview()
                                            }
                                        }
                                    }
                                }
                            },
                            onDidExitRegion: {

                            }
                        )
                    }
                }
            }
        }

        if let inProgressRoute = RouteService.sharedService().inProgressRoute {
            if inProgressRoute.disposedOfAllWorkOrders {
                RouteService.sharedService().fetchInProgressRouteOriginDrivingDirectionsFromCoordinate(location.coordinate, onDrivingDirectionsFetched: callback)
            } else {
                WorkOrderService.sharedService().fetchInProgressWorkOrderDrivingDirectionsFromCoordinate(location.coordinate, onDrivingDirectionsFetched: callback)
            }
        } else {
            WorkOrderService.sharedService().fetchInProgressWorkOrderDrivingDirectionsFromCoordinate(location.coordinate, onDrivingDirectionsFetched: callback)
        }
    }

    private func unregisterMonitoredRegions() {
        if let regions = regions {
            for region in regions {
                self.regions.removeObject(region)
                LocationService.sharedService().unregisterRegionMonitor(region.identifier)
            }
        }
    }

    func calculateBearing(toCoordinate: CLLocationCoordinate2D) -> CLLocationDegrees {
        if let location = LocationService.sharedService().location {
            let lon = location.coordinate.longitude - toCoordinate.longitude
            let y = sin(lon) * cos(toCoordinate.latitude)
            let x = cos(location.coordinate.latitude) * sin(toCoordinate.latitude) - sin(location.coordinate.latitude) * cos(toCoordinate.latitude) * cos(lon)
            let angle = atan2(y, x)
            return angle
        }
        return 0.0
    }

    func refreshInstructions() {
        if let directions = directions {
            if let route = directions.selectedRoute {
                if let leg = route.currentLeg {
                    directionsInstructionView.routeLeg = leg
                }
            }
        }
    }

//    // MARK: Navigation item
//
//    func setupNavigationItem(cancelItemEnabled: Bool = false) {
//        if let navigationItem = directionsViewControllerDelegate.navigationControllerNavigationItemForViewController?(self) {
//            if let directions = directions {
//                if let route = directions.selectedRoute() {
//                    if let leg = route.currentLeg {
//                        log("steps \(leg.steps)")
//                        let title = leg.steps[0].htmlInstructions
//                        log("title \(title)")
//                        navigationItem.title = title
//                    }
//                }
//            }
//        }
//    }

    private func renderRouteOverview() {
        if let mapView = directionsViewControllerDelegate.mapViewForDirectionsViewController(self) {
            mapView.removeOverlays(mapView.overlays)

            if let directions = directions {
                mapView.addOverlay(directions.selectedRoute.overviewPolyline, level: .AboveRoads)
            }
        }
    }

    // MARK: Status indicator

    func showProgressIndicator() {
        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseOut,
            animations: {

            },
            completion: { complete in
                self.showActivity()
            }
        )
    }

    func hideProgressIndicator() {
        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseOut,
            animations: {

            },
            completion: { complete in
                self.hideActivity()
            }
        )
    }

    // MARK Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        switch segue.identifier! {
        case "DirectionsViewControllerUnwindSegue":
            assert(segue.sourceViewController is DirectionsViewController)
            unwind()
        default:
            break
        }
    }

    func unwind() {
        unregisterMonitoredRegions()

        if let mapView = directionsViewControllerDelegate.mapViewForDirectionsViewController(self) {
            if let mapView = mapView as? WorkOrderMapView {
                mapView.removeAnnotations()
                mapView.setCenterCoordinate(mapView.userLocation.coordinate, fromEyeCoordinate: mapView.userLocation.coordinate, eyeAltitude: 0.0, pitch: 60.0, animated: true)
            }
        }

        if let navigationItem = directionsViewControllerDelegate?.navigationControllerNavigationItemForViewController(self) {
            navigationItem.prompt = nil
        }

        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseIn,
            animations: {
                self.view.alpha = 0
                self.view.frame = CGRect(
                    x: self.view.frame.origin.x,
                    y: self.view.frame.origin.y + self.view.frame.height,
                    width: self.view.frame.width,
                    height: self.view.frame.height
                )
            },
            completion: { complete in
                self.view.removeFromSuperview()
                if let mapView = self.directionsViewControllerDelegate.mapViewForDirectionsViewController(self) {
                    mapView.removeOverlays(mapView.overlays)
                    mapView.enableUserInteraction()
                    mapView.camera.pitch = 0.0
                }

                LocationService.sharedService().removeOnHeadingResolvedDurableCallback(self.defaultHeadingResolvedDurableCallbackKey)
                LocationService.sharedService().removeOnLocationResolvedDurableCallback(self.defaultLocationResolvedDurableCallbackKey)

                CheckinService.sharedService().disableNavigationAccuracy()
                LocationService.sharedService().disableNavigationAccuracy()
            }
        )
    }

    func routeLegAtIndex(i: Int) -> RouteLeg? {
        var routeLeg: RouteLeg!
        if let directions = directions {
            if let selectedRoute = directions.selectedRoute {
                routeLeg = selectedRoute.legs[i]
            }
        }
        return routeLeg
    }

    func routeLegStepAtIndexPath(indexPath: NSIndexPath) -> RouteLegStep! {
        var routeLegStep: RouteLegStep!
        if let routeLeg = routeLegAtIndex(indexPath.section) {
            if indexPath.row < routeLeg.steps.count {
                routeLegStep = routeLeg.steps[indexPath.row]
            }
        }
        return routeLegStep
    }
}
