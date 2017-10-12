//
//  DirectionsViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

protocol DirectionsViewControllerDelegate: class {
    func isPresentingDirections() -> Bool
    func finalDestinationForDirectionsViewController(_ directionsViewController: DirectionsViewController) -> CLLocationCoordinate2D
    func mapViewForDirectionsViewController(_ directionsViewController: DirectionsViewController) -> MKMapView
    func navbarPromptForDirectionsViewController(_ viewController: UIViewController) -> String?
    func navigationControllerForViewController(_ viewController: UIViewController) -> UINavigationController?
    func navigationControllerNavigationItemForViewController(_ viewController: UIViewController) -> UINavigationItem?
    func mapViewUserTrackingMode(_ mapView: MKMapView) -> MKUserTrackingMode
    func targetViewForViewController(_ viewController: UIViewController) -> UIView
}

class DirectionsViewController: ViewController {

    private let monitoredRegionsQueue = DispatchQueue(label: "api.amonitoredRegionsQueue", attributes: [])

    private let defaultMapCameraPitch = 60.0
    private let defaultMapCameraAltitude = 500.0

    private let defaultLocationResolvedDurableCallbackKey = "directionsLocationDurableCallback"
    private let defaultHeadingResolvedDurableCallbackKey = "directionsHeadingDurableCallback"

    private var regions: [CLCircularRegion]!
    private var lastRegionCrossed: CLCircularRegion!
    private var lastRegionCrossing: Date!

    @IBOutlet private weak var directionsInstructionView: DirectionsInstructionView!

    private var directions: Directions? {
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

                if let navigationItem = directionsViewControllerDelegate?.navigationControllerNavigationItemForViewController(self), let prompt = directionsViewControllerDelegate?.navbarPromptForDirectionsViewController(self) {
                    navigationItem.prompt = prompt
                } else {
                    navigationItem.prompt = nil
                }
            }
        }
    }

    private func resolveCurrentStep() { // FIXME -- move this to the route model
        if let leg = directions?.selectedRoute?.currentLeg, let nextStep = leg.nextStep {
            leg.currentStep.instruction = nextStep.instruction
            leg.currentStep.maneuver = nextStep.maneuver
        }
    }

    weak var directionsViewControllerDelegate: DirectionsViewControllerDelegate?

    private var targetView: UIView {
        return directionsViewControllerDelegate!.targetViewForViewController(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: Rendering

    func render() {
        if let mapView = directionsViewControllerDelegate?.mapViewForDirectionsViewController(self) as? WorkOrderMapView {
            if let inProgressWorkOrder = WorkOrderService.shared.inProgressWorkOrder {
                mapView.addAnnotation(inProgressWorkOrder.annotation)
            }

            mapView.disableUserInteraction()
            mapView.setCenterCoordinate(mapView.userLocation.coordinate, fromEyeCoordinate: mapView.userLocation.coordinate, eyeAltitude: defaultMapCameraAltitude, pitch: CGFloat(defaultMapCameraPitch), animated: true)
            mapView.directionsViewControllerDelegate = directionsViewControllerDelegate
        }

        let frame = CGRect(x: 0, y: targetView.height, width: targetView.width, height: view.height)

        view.alpha = 0.0
        view.frame = frame

        targetView.addSubview(view)

        directionsInstructionView.frame = CGRect(
            x: directionsInstructionView.frame.origin.x,
            y: directionsInstructionView.frame.origin.y,
            width: targetView.width,
            height: directionsInstructionView.height
        )

        directionsInstructionView.routeLeg = nil
        refreshInstructions()

        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
            self.view.alpha = 1
            self.view.frame = CGRect(x: frame.origin.x, y: frame.origin.y - self.view.height, width: frame.width, height: frame.height)
        }, completion: { completed in
            LocationService.shared.resolveCurrentLocation(self.defaultLocationResolvedDurableCallbackKey, allowCachedLocation: false) { location in
                if self.directions != nil {
                    self.setCenterCoordinate(location)
                }

                if let lastRegionCrossing = self.lastRegionCrossing {
                    if abs(lastRegionCrossing.timeIntervalSinceNow) >= 5.0 && self.lastRegionCrossed != nil && !self.lastRegionCrossed.contains(location.coordinate) {
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
                        if abs(lastRegionCrossing.timeIntervalSinceNow) >= 5.0 && self.lastRegionCrossed != nil && !self.lastRegionCrossed.contains(location.coordinate) {
                            self.directions = nil
                        }
                    } else {
                        self.fetchDrivingDirections(location)
                    }
                }
            }
        })
    }

    private func setCenterCoordinate(_ location: CLLocation) {
        if let mapView = directionsViewControllerDelegate?.mapViewForDirectionsViewController(self) {
            var sufficientDelta = false
            if let lastLocation = LocationService.shared.currentLocation {
                let lastCoordinate = lastLocation.coordinate
                let region = CLCircularRegion(center: lastCoordinate, radius: 2.5, identifier: "sufficientDeltaRegionMonitor")
                sufficientDelta = !region.contains(location.coordinate)
            } else {
                sufficientDelta = true
            }

            if sufficientDelta {
                if let directions = directions {
                    let distance = MKMetersBetweenMapPoints(MKMapPointForCoordinate(location.coordinate), MKMapPointForCoordinate(directions.selectedRoute.currentLeg.currentStep.startCoordinate))

                    let cameraAltitude = distance / tan(Double.pi*(15 / 180.0))

                    mapView.setCenterCoordinate(location.coordinate,
                                                fromEyeCoordinate: directions.selectedRoute.currentLeg.currentStep.startCoordinate,
                                                eyeAltitude: cameraAltitude,
                                                pitch: CGFloat(defaultMapCameraPitch),
                                                heading: calculateBearing(directions.selectedRoute.currentLeg.currentStep.startCoordinate),
                                                animated: false)
                }
            }
        }
    }

    private func fetchDrivingDirections(_ location: CLLocation!) {
        let callback: OnDrivingDirectionsFetched = { directions in
            self.directions = directions

            self.setCenterCoordinate(location)

            for leg in directions.selectedRoute.legs {
                for step in [leg.currentStep] {
                    for coordinate in (step?.shapeCoordinates)! {
                        let overlay = MKCircle(center: coordinate, radius: 5.0)
                        let identifier = (step?.identifier)! + "_\(coordinate.latitude),\(coordinate.longitude)"
                        let region = CLCircularRegion(center: overlay.coordinate, radius: overlay.radius, identifier: identifier)

                        self.regions.append(region)

                        LocationService.shared.monitorRegion(region, onDidEnterRegion: {
                            self.lastRegionCrossed = region
                            self.lastRegionCrossing = NSDate() as Date!

                            self.regions.removeObject(region)
                            LocationService.shared.unregisterRegionMonitor(region.identifier)

                            if let currentLeg = self.directions?.selectedRoute.currentLeg, let currentStep = currentLeg.currentStep {
                                var identifier = ""
                                if let currentShapeCoordinate = currentStep.currentShapeCoordinate, let currentStepIdentifier = currentStep.identifier {
                                    identifier = currentStepIdentifier + "_\(currentShapeCoordinate.latitude),\(currentShapeCoordinate.longitude)"
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
                                    for shapeCoord in Array(currentStep.shapeCoordinates.reversed()) {
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

                                DispatchQueue.main.async {
                                    self.resolveCurrentStep()
                                    self.refreshInstructions()
                                    self.renderRouteOverview()
                                }
                            }
                        }, onDidExitRegion: {

                        })
                    }
                }
            }
        }

        WorkOrderService.shared.fetchInProgressWorkOrderDrivingDirectionsFromCoordinate(location.coordinate, onDrivingDirectionsFetched: callback)
    }

    private func unregisterMonitoredRegions() {
        monitoredRegionsQueue.async { [weak self] in
            if let regions = self?.regions {
                for region in regions {
                    self?.regions.removeObject(region)
                    LocationService.shared.unregisterRegionMonitor(region.identifier)
                }
            }
        }
    }

    private func calculateBearing(_ toCoordinate: CLLocationCoordinate2D) -> CLLocationDegrees {
        guard let location = LocationService.shared.location else { return 0 }

        let lon = location.coordinate.longitude - toCoordinate.longitude
        let y = sin(lon) * cos(toCoordinate.latitude)
        let x = cos(location.coordinate.latitude) * sin(toCoordinate.latitude) - sin(location.coordinate.latitude) * cos(toCoordinate.latitude) * cos(lon)
        let angle = atan2(y, x)
        return angle
    }

    private func refreshInstructions() {
        if let leg = directions?.selectedRoute?.currentLeg {
            directionsInstructionView.routeLeg = leg
        }
    }

    private func renderRouteOverview() {
        if let mapView = directionsViewControllerDelegate?.mapViewForDirectionsViewController(self) {
            mapView.removeOverlays(mapView.overlays)

            if let directions = directions {
                mapView.add(directions.selectedRoute.overviewPolyline, level: .aboveRoads)
            }
        }
    }

    // MARK: Status indicator

    private func showProgressIndicator() {
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {

        }, completion: { completed in
            self.showActivity()
        })
    }

    private func hideProgressIndicator() {
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {

        }, completion: { completed in
            self.hideActivity()
        })
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "DirectionsViewControllerUnwindSegue":
            assert(segue.source is DirectionsViewController)
            unwind()
        default:
            break
        }
    }

    private func unwind() {
        unregisterMonitoredRegions()

        LocationService.shared.removeOnHeadingResolvedDurableCallback(defaultHeadingResolvedDurableCallbackKey)
        LocationService.shared.removeOnLocationResolvedDurableCallback(defaultLocationResolvedDurableCallbackKey)

        CheckinService.shared.disableNavigationAccuracy()
        LocationService.shared.disableNavigationAccuracy()

        if let mapView = directionsViewControllerDelegate?.mapViewForDirectionsViewController(self) as? WorkOrderMapView {
            mapView.removeAnnotations()
            mapView.setCenterCoordinate(mapView.userLocation.coordinate, fromEyeCoordinate: mapView.userLocation.coordinate, eyeAltitude: 0.0, pitch: 60.0, animated: true)
        }

        if let navigationItem = directionsViewControllerDelegate?.navigationControllerNavigationItemForViewController(self) {
            navigationItem.prompt = nil
        }

        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
            self.view.alpha = 0
            self.view.frame = CGRect(
                x: self.view.frame.origin.x,
                y: self.view.frame.origin.y + self.view.height,
                width: self.view.width,
                height: self.view.height
            )
        }, completion: { completed in
            self.view.removeFromSuperview()
            if let mapView = self.directionsViewControllerDelegate?.mapViewForDirectionsViewController(self) {
                mapView.removeOverlays(mapView.overlays)
                mapView.enableUserInteraction()
                mapView.camera.pitch = 0.0
            }
        })
    }

    private func routeLegAtIndex(_ i: Int) -> RouteLeg? {
        var routeLeg: RouteLeg!
        if let selectedRoute = directions?.selectedRoute {
            routeLeg = selectedRoute.legs[i]
        }
        return routeLeg
    }

    private func routeLegStepAtIndexPath(_ indexPath: IndexPath) -> RouteLegStep? {
        var routeLegStep: RouteLegStep?
        if let routeLeg = routeLegAtIndex(indexPath.section), indexPath.row < routeLeg.steps.count {
            routeLegStep = routeLeg.steps[indexPath.row]
        }
        return routeLegStep
    }
}
