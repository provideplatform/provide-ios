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
    func mapViewUserTrackingMode(_ mapView: MKMapView) -> MKUserTrackingMode
}

class DirectionsViewController: ViewController {

    private weak var targetView: UIView?
    private weak var workOrderMapView: WorkOrderMapView?
    private weak var directionsViewControllerDelegate: DirectionsViewControllerDelegate?

    func configure(targetView: UIView, mapView: WorkOrderMapView, delegate: DirectionsViewControllerDelegate) {
        self.targetView = targetView
        self.workOrderMapView = mapView
        self.directionsViewControllerDelegate = delegate
    }

    private let monitoredRegionsQueue = DispatchQueue(label: "api.amonitoredRegionsQueue", attributes: [])

    private let defaultMapCameraPitch: CGFloat = 60
    private let defaultMapCameraAltitude = 500.0

    private let defaultLocationResolvedDurableCallbackKey = "directionsLocationDurableCallback"
    private let defaultHeadingResolvedDurableCallbackKey = "directionsHeadingDurableCallback"

    private var regions: [CLCircularRegion]!
    private var lastRegionCrossed: CLCircularRegion!
    private var lastRegionCrossing: Date?

    @IBOutlet private weak var directionsInstructionView: DirectionsInstructionView!

    private var directions: Directions? {
        didSet {
            if directions == nil {
                showProgressIndicator()

                unregisterMonitoredRegions()
                regions = []
                lastRegionCrossing = nil
            } else {
                hideProgressIndicator()

                resolveCurrentManeuver()
                refreshInstructions()
                renderRouteOverview()
            }
        }
    }

    private func resolveCurrentManeuver() { // FIXME -- move this to the route model
        if let leg = directions?.selectedRoute?.currentLeg, let nextManeuver = leg.nextManeuver {
            leg.currentManeuver.instruction = nextManeuver.instruction
            leg.currentManeuver.action = nextManeuver.action  // FIXME-- is this a bug?
        }
    }

    // MARK: Rendering

    func render() {
        if let mapView = workOrderMapView {
            if let inProgressWorkOrder = WorkOrderService.shared.inProgressWorkOrder {
                mapView.addAnnotation(inProgressWorkOrder.annotation)
            }

            mapView.disableUserInteraction()
            mapView.setCenterCoordinate(mapView.userLocation.coordinate, fromEyeCoordinate: mapView.userLocation.coordinate, eyeAltitude: defaultMapCameraAltitude, pitch: defaultMapCameraPitch, animated: true)
            mapView.directionsViewControllerDelegate = directionsViewControllerDelegate
        }

        let frame = CGRect(x: 0, y: targetView?.height ?? 0, width: targetView?.width ?? 0, height: view.height)

        view.alpha = 0.0
        view.frame = frame

        targetView?.addSubview(view)

        directionsInstructionView.frame = CGRect(
            x: directionsInstructionView.frame.origin.x,
            y: directionsInstructionView.frame.origin.y,
            width: targetView?.width ?? 0,
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
                    self.regions = []
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
        if let mapView = workOrderMapView {
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
                    let distance = MKMetersBetweenMapPoints(MKMapPointForCoordinate(location.coordinate),
                                                            MKMapPointForCoordinate(directions.selectedRoute!.currentLeg.currentManeuver.startCoordinate!))

                    let cameraAltitude = distance / tan(Double.pi*(15 / 180.0))

                    mapView.setCenterCoordinate(location.coordinate,
                                                fromEyeCoordinate: directions.selectedRoute!.currentLeg.currentManeuver.startCoordinate!,
                                                eyeAltitude: cameraAltitude,
                                                pitch: defaultMapCameraPitch,
                                                heading: calculateBearing(directions.selectedRoute!.currentLeg.currentManeuver.startCoordinate!),
                                                animated: false)
                }
            }
        }
    }

    private func fetchDrivingDirections(_ location: CLLocation!) {
        let callback: OnDrivingDirectionsFetched = { directions in
            self.directions = directions

            self.setCenterCoordinate(location)

            for leg in directions.selectedRoute?.legs ?? [] {
                for step in [leg.currentManeuver] {
                    for coordinate in step?.shapeCoordinates ?? [] {
                        let overlay = MKCircle(center: coordinate, radius: 5.0)
                        let identifier = (step?.id)! + "_\(coordinate.latitude),\(coordinate.longitude)"
                        let region = CLCircularRegion(center: overlay.coordinate, radius: overlay.radius, identifier: identifier)

                        self.regions.append(region)

                        LocationService.shared.monitorRegion(region, onDidEnterRegion: {
                            self.lastRegionCrossed = region
                            self.lastRegionCrossing = NSDate() as Date!

                            self.regions.removeObject(region)
                            LocationService.shared.unregisterRegionMonitor(region.identifier)

                            if let currentLeg = self.directions?.selectedRoute?.currentLeg, let currentManeuver = currentLeg.currentManeuver {
                                var identifier = ""
                                if let currentShapeCoordinate = currentManeuver.currentShapeCoordinate, let currentManeuverIdentifier = currentManeuver.id {
                                    identifier = currentManeuverIdentifier + "_\(currentShapeCoordinate.latitude),\(currentShapeCoordinate.longitude)"
                                }

                                if self.lastRegionCrossed.identifier == identifier {
                                    currentManeuver.currentShapeIndex += 1

                                    if currentManeuver.isFinished {
                                        currentLeg.currentManeuverIndex += 1
                                    }
                                } else if self.lastRegionCrossed.center.latitude == currentManeuver.endCoordinate!.latitude && self.lastRegionCrossed.center.longitude == currentManeuver.endCoordinate!.longitude {
                                    currentLeg.currentManeuverIndex += 1
                                } else {
                                    var shapeIndex = currentManeuver.shapes.count - 1
                                    for shapeCoord in Array(currentManeuver.shapeCoordinates.reversed()) {
                                        if self.lastRegionCrossed.center.latitude == shapeCoord.latitude && self.lastRegionCrossed.center.longitude == shapeCoord.longitude {
                                            currentManeuver.currentShapeIndex = shapeIndex
                                            if currentManeuver.isFinished {
                                                currentLeg.currentManeuverIndex += 1
                                            }
                                            break
                                        }
                                        shapeIndex -= 1
                                    }
                                }

                                DispatchQueue.main.async {
                                    self.resolveCurrentManeuver()
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
        if let mapView = workOrderMapView {
            mapView.removeOverlays(mapView.overlays)

            if let directions = directions {
                mapView.add(directions.selectedRoute!.overviewPolyline, level: .aboveRoads)
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

        if let mapView = workOrderMapView {
            mapView.removeAnnotations()
            mapView.setCenterCoordinate(mapView.userLocation.coordinate, fromEyeCoordinate: mapView.userLocation.coordinate, eyeAltitude: 0.0, pitch: 60.0, animated: true)
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
            if let mapView = self.workOrderMapView {
                mapView.removeOverlays(mapView.overlays)
                mapView.enableUserInteraction()
                mapView.camera.pitch = 0.0
            }
        })
    }

    private func routeLegAtIndex(_ i: Int) -> RouteLeg? {
        return directions?.selectedRoute?.legs[i]
    }

    private func maneuverAtIndexPath(_ indexPath: IndexPath) -> Maneuver? {
        if let routeLeg = routeLegAtIndex(indexPath.section), indexPath.row < routeLeg.maneuvers.count {
            return routeLeg.maneuvers[indexPath.row]
        } else {
            return nil
        }
    }
}
