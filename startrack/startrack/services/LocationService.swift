//
//  LocationService.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnHeadingResolved = (CLHeading) -> ()
typealias OnLocationResolved = (CLLocation) -> ()

class LocationService: CLLocationManager, CLLocationManagerDelegate {

    let defaultAccuracy = kCLLocationAccuracyBest
    let defaultDistanceFilter = kCLDistanceFilterNone

    var currentHeading: CLHeading!
    var currentLocation: CLLocation!

    private var geofenceCallbacks = [String : [String : VoidBlock]]()
    private var onManagerAuthorizedCallbacks = [VoidBlock]()

    private var onHeadingResolvedCallbacks = [OnHeadingResolved]()
    private var onHeadingResolvedDurableCallbacks = [String : OnHeadingResolved]()

    private var onLocationResolvedCallbacks = [OnLocationResolved]()
    private var onLocationResolvedDurableCallbacks = [String : OnLocationResolved]()

    private var requireNavigationAccuracy = false

    private var regions = [CLCircularRegion]()

    required override init() {
        super.init()
        delegate = self

        activityType = .AutomotiveNavigation
        pausesLocationUpdatesAutomatically = false

        desiredAccuracy = defaultAccuracy
        distanceFilter = defaultDistanceFilter
    }

    private static let sharedInstance = LocationService()

    class func sharedService() -> LocationService {
        return sharedInstance
    }

    // MARK: Authorization

    func requireAuthorization(callback: VoidBlock) {
        if CLLocationManager.authorizationStatus() == .AuthorizedAlways {
            callback()
        } else {
            onManagerAuthorizedCallbacks.append(callback)
            requestAlwaysAuthorization()
        }
    }

    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedAlways {
            while onManagerAuthorizedCallbacks.count > 0 {
                let callback = onManagerAuthorizedCallbacks.removeAtIndex(0)
                callback()
            }
        }
    }

    // MARK: Start/stop location updates

    func start() {
        startUpdatingLocation()

        log("Started location service updates")
    }

    func stop() {
        stopUpdatingLocation()
        stopUpdatingHeading()

        log("Stopped location service updates")
    }

    func foreground() {
        desiredAccuracy = defaultAccuracy
        distanceFilter = defaultDistanceFilter
    }

    func background() {
        if !requireNavigationAccuracy {
            distanceFilter = 99999.0
        }
    }

    // MARK: Navigation accuracy

    func enableNavigationAccuracy() {
        requireNavigationAccuracy = true
        desiredAccuracy = kCLLocationAccuracyBestForNavigation

        UIApplication.sharedApplication().idleTimerDisabled = true

        startUpdatingHeading()
    }

    func disableNavigationAccuracy() {
        requireNavigationAccuracy = false
        desiredAccuracy = defaultAccuracy

        UIApplication.sharedApplication().idleTimerDisabled = false

        stopUpdatingHeading()
    }

    // MARK: Location resolution

    func resolveCurrentLocation(durableKey: String? = nil, allowCachedLocation: Bool = false, onResolved: OnLocationResolved) {
        if allowCachedLocation && currentLocation != nil {
            onResolved(currentLocation)
        } else {
            foreground()
        }

        if durableKey != nil {
            onLocationResolvedDurableCallbacks[durableKey!] = onResolved
        } else if !allowCachedLocation {
            onLocationResolvedCallbacks.append(onResolved)
        }
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last where location.isAccurate {
            locationResolved(location)
        }
    }

    func removeOnLocationResolvedDurableCallback(key: String) {
        let callback = onLocationResolvedDurableCallbacks[key]
        if callback != nil {
            onLocationResolvedDurableCallbacks.removeValueForKey(key)
        }
    }

    private func locationResolved(location: CLLocation) {
        log("Resolved current location: \(location)")

        currentLocation = location

        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
        dispatch_async(queue) {
            for region in self.regions {
                if region.containsCoordinate(location.coordinate) {
                    if let callbacks = self.geofenceCallbacks[region.identifier] {
                        if let callback = callbacks["didEnterRegion"] {
                            callback()
                        }
                    }
                }
            }
        }

        while onLocationResolvedCallbacks.count > 0 {
            let callback = onLocationResolvedCallbacks.removeAtIndex(0)
            callback(location)
        }

        for callback in onLocationResolvedDurableCallbacks.values {
            callback(location)
        }
    }

    // MARK: Heading resolution

    func resolveCurrentHeading(onResolved: OnHeadingResolved) {
        resolveCurrentHeading(onResolved, durableKey: nil)
    }

    func resolveCurrentHeading(onResolved: OnHeadingResolved, allowCachedHeading: Bool) {
        resolveCurrentHeading(onResolved, durableKey: nil, allowCachedHeading: allowCachedHeading)
    }

    func resolveCurrentHeading(onResolved: OnHeadingResolved, durableKey: String?, allowCachedHeading: Bool = false) {
        if allowCachedHeading && currentHeading != nil {
            onResolved(currentHeading)
        } else if !requireNavigationAccuracy {
            startUpdatingHeading()
        }

        if let durableKey = durableKey {
            onHeadingResolvedDurableCallbacks[durableKey] = onResolved
        } else if !allowCachedHeading {
            onHeadingResolvedCallbacks.append(onResolved)
        }
    }

    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if abs(newHeading.timestamp.timeIntervalSinceNow) < 1.0 && newHeading.headingAccuracy >= 0.0 {
            headingResolved(newHeading)
        }
    }

    func removeOnHeadingResolvedDurableCallback(key: String) {
        let callback = onHeadingResolvedDurableCallbacks[key]
        if callback != nil {
            onHeadingResolvedDurableCallbacks.removeValueForKey(key)
        }
    }

    private func headingResolved(heading: CLHeading) {
        log("Resolved current heading: \(heading)")
        currentHeading = heading

        while onHeadingResolvedCallbacks.count > 0 {
            let callback = onHeadingResolvedCallbacks.removeAtIndex(0)
            callback(heading)
        }

        for callback in onHeadingResolvedDurableCallbacks.values {
            callback(heading)
        }

        if !requireNavigationAccuracy {
            stopUpdatingHeading()
        }
    }

    // MARK: Geofencing

    func monitorRegion(region: CLCircularRegion, onDidEnterRegion: VoidBlock, onDidExitRegion: VoidBlock) {
        monitorRegionWithCircularOverlay(MKCircle(centerCoordinate: region.center, radius: region.radius),
                                         identifier: region.identifier,
                                         onDidEnterRegion: onDidEnterRegion,
                                         onDidExitRegion: onDidExitRegion)
    }

    func monitorRegionWithCircularOverlay(overlay: MKCircle, identifier: String, onDidEnterRegion: VoidBlock, onDidExitRegion: VoidBlock) {
        if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
            return
        }

        var radius = overlay.radius
        if radius > maximumRegionMonitoringDistance {
            radius = maximumRegionMonitoringDistance
        }

        var callbacks = geofenceCallbacks[identifier]

        if callbacks == nil {
            callbacks = [String : VoidBlock]()
        }

        callbacks!["didEnterRegion"] = onDidEnterRegion

        callbacks!["didExitRegion"] = onDidExitRegion

        geofenceCallbacks[identifier] = callbacks

        let region = CLCircularRegion(center: overlay.coordinate, radius: radius, identifier: identifier)
        regions.append(region)
    }

    func unregisterRegionMonitor(identifier: String) {
        for region in regions {
            if region.identifier == identifier {
                geofenceCallbacks.removeValueForKey(region.identifier)
                regions.removeObject(region)
                break
            }
        }
    }

    func unregisterRegionMonitors() {
        if regions.count > 0 {
            for region in regions {
                geofenceCallbacks.removeValueForKey(region.identifier)
            }

            regions = [CLCircularRegion]()
        }
    }

    func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        log("Started monitoring region \(region)")
    }

    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let callbacks = geofenceCallbacks[region.identifier] {
            if let callback = callbacks["didEnterRegion"] {
                callback()
            }
        }
    }

    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let callbacks = geofenceCallbacks[region.identifier] {
            if let callback = callbacks["didExitRegion"] {
                callback()
            }
        }
    }
}