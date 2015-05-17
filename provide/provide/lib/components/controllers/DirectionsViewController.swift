//
//  DirectionsViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

@objc
protocol DirectionsViewControllerDelegate {

    func isPresentingDirections() -> Bool
    func finalDestinationForDirectionsViewController(directionsViewController: DirectionsViewController!) -> CLLocationCoordinate2D
    func mapViewForDirectionsViewController(directionsViewController: DirectionsViewController!) -> MKMapView!

    optional func navigationControllerForViewController(viewController: ViewController!) -> UINavigationController!
    optional func navigationControllerNavigationItemForViewController(viewController: ViewController!) -> UINavigationItem!

    optional func mapViewUserTrackingMode(mapView: MKMapView!) -> MKUserTrackingMode

    optional func targetViewForViewController(viewController: ViewController!) -> UIView!

}

class DirectionsViewController: ViewController {

    private let defaultMapCameraPitch = 75.0
    private let defaultMapCameraAltitude = 200.0

    private let defaultLocationResolvedDurableCallbackKey = "directionsLocationDurableCallback"
    private let defaultHeadingResolvedDurableCallbackKey = "directionsHeadingDurableCallback"

    private var regions: [CLCircularRegion]!
    private var lastRegionCrossed: CLCircularRegion!
    private var lastRegionCrossing: NSDate!

    @IBOutlet private weak var directionsInstructionView: DirectionsInstructionView!

    var directions: Directions! {
        didSet {
            if directions == nil {
                showProgressIndicator()

                self.unregisterMonitoredRegions()
                self.regions = [CLCircularRegion]()
                self.lastRegionCrossing = nil
            } else {
                hideProgressIndicator()

                resolveCurrentStep()
                refreshInstructions()
                renderRouteOverview()
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

    private var targetView: UIView! {
        get {
            return directionsViewControllerDelegate.targetViewForViewController?(self)
        }
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        showProgressIndicator()
    }

    // MARK: Rendering

    func render() {
        if let mapView = directionsViewControllerDelegate.mapViewForDirectionsViewController(self) {
            if mapView is WorkOrderMapView {
                mapView.addAnnotation(WorkOrderService.sharedService().inProgressWorkOrder)
                mapView.disableUserInteraction()

                mapView.setCenterCoordinate(mapView.userLocation.coordinate,
                                            fromEyeCoordinate: mapView.userLocation.coordinate,
                                            eyeAltitude: 0.0,
                                            pitch: CGFloat(defaultMapCameraPitch),
                                            animated: true)

                (mapView as! WorkOrderMapView).directionsViewControllerDelegate = self.directionsViewControllerDelegate
            }
        }

        let frame = CGRectMake(0.0,
                               targetView.frame.size.height,
                               targetView.frame.size.width,
                               view.frame.size.height)

        view.alpha = 0.0
        view.frame = frame

        targetView.addSubview(view)

        directionsInstructionView.frame = CGRectMake(directionsInstructionView.frame.origin.x,
                                                     directionsInstructionView.frame.origin.y,
                                                     targetView.frame.size.width,
                                                     directionsInstructionView.frame.size.height)

        directionsInstructionView.routeLeg = nil
        refreshInstructions()

        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: { () -> Void in
                self.view.alpha = 1
                self.view.frame = CGRectMake(frame.origin.x,
                                             frame.origin.y - self.view.frame.size.height,
                                             frame.size.width,
                                             frame.size.height)

            },
            completion: { (complete) -> Void in
                LocationService.sharedService().resolveCurrentLocation({ (location) -> () in
                    var cameraPitch: CGFloat = CGFloat(self.defaultMapCameraPitch)
                    var cameraAltitude: Double = self.defaultMapCameraAltitude

//                    var cameraHeading: Double = 0.0
//                    if let heading = LocationService.sharedService().currentHeading {
//                        cameraHeading = heading.trueHeading
//                    }

                    if let directions = self.directions {
                        if let mapView = self.directionsViewControllerDelegate.mapViewForDirectionsViewController(self) {
                            mapView.setCenterCoordinate(location.coordinate,
                                fromEyeCoordinate: directions.selectedRoute.currentLeg.currentStep.startCoordinate,
                                eyeAltitude: cameraAltitude,
                                heading: -1, //360.0 * (1.0 - self.calculateBearing(self.directions.selectedRoute.currentLeg.currentStep.endCoordinate)),
                                pitch: cameraPitch,
                                animated: false)
                        }
                    }

                    if let lastRegionCrossing = self.lastRegionCrossing {
                        if abs(lastRegionCrossing.timeIntervalSinceNow) >= 5.0 && self.lastRegionCrossed != nil && self.lastRegionCrossed.containsCoordinate(location.coordinate) == false {
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
                            if abs(lastRegionCrossing.timeIntervalSinceNow) >= 5.0 && self.lastRegionCrossed != nil && self.lastRegionCrossed.containsCoordinate(location.coordinate) == false {
                                self.directions = nil

                            }
                        } else {
                            self.fetchDrivingDirections(location)
                        }
                    }
                }, durableKey: self.defaultLocationResolvedDurableCallbackKey, allowCachedLocation: false)
            }
        )
    }

    private func fetchDrivingDirections(location: CLLocation!) {
        var cameraPitch: CGFloat = CGFloat(self.defaultMapCameraPitch)
        var cameraAltitude: Double = self.defaultMapCameraAltitude

        WorkOrderService.sharedService().fetchInProgressWorkOrderDrivingDirectionsFromCoordinate(location.coordinate, onWorkOrderDrivingDirectionsFetched: { (workOrder, directions) -> () in
            self.directions = directions

            if let mapView = self.directionsViewControllerDelegate.mapViewForDirectionsViewController(self) {
                mapView.setCenterCoordinate(location.coordinate,
                    fromEyeCoordinate: self.directions.selectedRoute.currentLeg.currentStep.startCoordinate,
                    eyeAltitude: cameraAltitude,
                    heading: -1, //360.0 * (1.0 - self.calculateBearing(self.directions.selectedRoute.currentLeg.currentStep.endCoordinate)),
                    pitch: cameraPitch,
                    animated: false)
            }

            for leg in self.directions.selectedRoute.legs {
                for step in [(leg as! RouteLeg).currentStep] {
                    for coordinate in (step as RouteLegStep).shapeCoordinates {
                        let overlay = MKCircle(centerCoordinate: coordinate, radius: 5.0)
                        let identifier = (step as RouteLegStep).identifier + "_\(coordinate.latitude),\(coordinate.longitude)"
                        let region = CLCircularRegion(center: overlay.coordinate, radius: overlay.radius, identifier: identifier)

                        self.regions.append(region)

                        LocationService.sharedService().monitorRegion(region, onDidEnterRegion: { () -> Void in
                            self.lastRegionCrossed = region
                            self.lastRegionCrossing = NSDate()

                            LocationService.sharedService().unregisterRegionMonitor(region.identifier)
                            self.regions.removeObject(region)

                            if let directions = self.directions {
                                if let currentLeg = directions.selectedRoute.currentLeg {
                                    if let currentStep = currentLeg.currentStep {
                                        var identifier = currentStep.identifier + "_\(currentStep.currentShapeCoordinate.latitude),\(currentStep.currentShapeCoordinate.longitude)"
                                        if self.lastRegionCrossed.identifier == identifier {
                                            currentStep.currentShapeIndex += 1

                                            if currentStep.isFinished {
                                                currentLeg.currentStepIndex += 1
                                            }
                                        } else if self.lastRegionCrossed.center.latitude == currentStep.endCoordinate.latitude && self.lastRegionCrossed.center.longitude == currentStep.endCoordinate.longitude {
                                            currentLeg.currentStepIndex += 1
                                        } else {
                                            var shapeIndex = currentStep.shape.count - 1
                                            for shapeCoord in currentStep.shapeCoordinates.reverse() {
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
                            }, onDidExitRegion: { () -> Void in

                        })
                    }
                }
            }
        })
    }

    private func unregisterMonitoredRegions() {
        if let regions = self.regions {
            for region in regions {
                LocationService.sharedService().unregisterRegionMonitor(region.identifier)
                self.regions.removeObject(region)
            }
        }
    }

    func calculateBearing(toCoordinate: CLLocationCoordinate2D) -> CLLocationDegrees {
        if let location = LocationService.sharedService().location {
            var lon = location.coordinate.longitude - toCoordinate.longitude
            var y = sin(lon) * cos(toCoordinate.latitude)
            var x = cos(location.coordinate.latitude) * sin(toCoordinate.latitude) - sin(location.coordinate.latitude) * cos(toCoordinate.latitude) * cos(lon)
            var angle = atan2(y, x)
            return angle
        }
        return 0.0
    }

    func refreshInstructions() {
        if let directions = self.directions {
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
//            if let directions = self.directions {
//                if let route = directions.selectedRoute() {
//                    if let leg = route.currentLeg {
//                        println("steps \(leg.steps)")
//                        var title = leg.steps[0].htmlInstructions
//                        println("title \(title)")
//                        navigationItem.title = title
//                    }
//                }
//            }
//        }
//    }

    private func renderRouteOverview() {
        if let mapView = directionsViewControllerDelegate.mapViewForDirectionsViewController(self) {
            mapView.removeOverlays(mapView.overlays)

            if let directions = self.directions {
                if let overview = directions.selectedRoute.overviewPolyline {
                    mapView.addOverlay(overview, level: .AboveRoads)
                }
            }
        }
    }

    // MARK: Status indicator

    func showProgressIndicator() {
        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseOut,
            animations: { () -> Void in

            },
            completion: { (complete) -> Void in
                self.showActivity()
            }
        )
    }

    func hideProgressIndicator() {
        UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseOut,
            animations: { () -> Void in

            },
            completion: { (complete) -> Void in
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
            break
        default:
            break
        }
    }

    func unwind() {
        unregisterMonitoredRegions()

        if let mapView = directionsViewControllerDelegate.mapViewForDirectionsViewController(self) {
            if mapView is WorkOrderMapView {
                (mapView as! WorkOrderMapView).removeAnnotations()
                mapView.setCenterCoordinate(mapView.userLocation.coordinate, fromEyeCoordinate: mapView.userLocation.coordinate, eyeAltitude: 0.0, pitch: 60.0, animated: true)
            }
        }

        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseIn,
            animations: { () -> Void in
                self.view.alpha = 0
                self.view.frame = CGRectMake(self.view.frame.origin.x,
                                             self.view.frame.origin.y + self.view.frame.size.height,
                                             self.view.frame.size.width,
                                             self.view.frame.size.height)

            },
            completion: { (complete) -> Void in
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

                //self.clearNavigationItem()
            }
        )
    }

    func routeLegAtIndex(i: Int) -> RouteLeg! {
        var routeLeg: RouteLeg!
        if let directions = self.directions {
            if let selectedRoute = directions.selectedRoute {
                routeLeg = selectedRoute.legs[i] as! RouteLeg
            }
        }
        return routeLeg
    }

    func routeLegStepAtIndexPath(indexPath: NSIndexPath) -> RouteLegStep! {
        var routeLegStep: RouteLegStep!
        if let routeLeg = routeLegAtIndex(indexPath.section) {
            if let steps = routeLeg.steps {
                routeLegStep = steps[indexPath.row] as! RouteLegStep
            }
        }
        return routeLegStep
    }

}
