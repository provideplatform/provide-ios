//
//  LocationService.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import KTSwiftExtensions

typealias OnHeadingResolved = (CLHeading) -> Void
typealias OnLocationResolved = (CLLocation) -> Void
typealias OnLocationAndHeadingResolved = (CLLocation, CLHeading) -> Void
typealias OnReverseGeocodeResolved = (CLPlacemark) -> Void

class LocationService: CLLocationManager, CLLocationManagerDelegate {

    let defaultAccuracy = kCLLocationAccuracyBest
    let defaultDistanceFilter = kCLDistanceFilterNone

    fileprivate let regionMonitorModificationQueue = DispatchQueue(label: "api.regionMonitorModificationQueue", attributes: [])

    var currentHeading: CLHeading!
    var currentLocation: CLLocation!

    fileprivate var intervalSinceLastAccurateLocation: TimeInterval! {
        if let locationServiceStartedDate = locationServiceStartedDate {
            if let lastAccurateLocationDate = lastAccurateLocationDate {
                return lastAccurateLocationDate.timeIntervalSince(locationServiceStartedDate)
            }
        }
        return nil
    }

    fileprivate var locationServiceStartedDate: Date!
    fileprivate var lastAccurateLocationDate: Date!

    fileprivate var geofenceCallbacks = [String: [String: VoidBlock]]()
    fileprivate var geofenceCallbackCounts = [String: [String: Int]]()
    fileprivate var onManagerAuthorizedCallbacks = [VoidBlock]()

    fileprivate var onHeadingResolvedCallbacks = [OnHeadingResolved]()
    fileprivate var onHeadingResolvedDurableCallbacks = [String: OnHeadingResolved]()

    fileprivate var onLocationResolvedCallbacks = [OnLocationResolved]()
    fileprivate var onLocationResolvedDurableCallbacks = [String: OnLocationResolved]()

    fileprivate var onLocationAndHeadingResolvedCallbacks = [OnLocationAndHeadingResolved]()
    fileprivate var onLocationAndHeadingResolvedDurableCallbacks = [String: OnLocationAndHeadingResolved]()

    fileprivate var requireNavigationAccuracy = false

    fileprivate var regions = [CLCircularRegion]()

    fileprivate var staleLocation: Bool {
        if intervalSinceLastAccurateLocation != nil && abs(intervalSinceLastAccurateLocation) >= 15.0 {
            return true
        } else if locationServiceStartedDate != nil && abs(locationServiceStartedDate.timeIntervalSinceNow) >= 15.0 {
            return true
        }
        return false
    }

    required override init() {
        super.init()
        delegate = self

        activityType = .automotiveNavigation
        pausesLocationUpdatesAutomatically = false

        desiredAccuracy = defaultAccuracy
        distanceFilter = defaultDistanceFilter
    }

    fileprivate static let sharedInstance = LocationService()

    class func sharedService() -> LocationService {
        return sharedInstance
    }

    // MARK: Authorization

    func requireAuthorization(_ callback: @escaping VoidBlock) {
        if CLLocationManager.authorizationStatus() == .authorizedAlways {
            callback()
        } else {
            NotificationCenter.default.postNotificationName("ApplicationWillRequestLocationAuthorization")
            onManagerAuthorizedCallbacks.append(callback)
            requestAlwaysAuthorization()
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            while onManagerAuthorizedCallbacks.count > 0 {
                let callback = onManagerAuthorizedCallbacks.remove(at: 0)
                callback()
            }
        }
    }

    // MARK: Start/stop location updates

    func start() {
        if locationServiceStartedDate == nil {
            locationServiceStartedDate = Date()

            startUpdatingLocation()
            startUpdatingHeading()

            logInfo("Started location service updates")
        }
    }

    func stop() {
        locationServiceStartedDate = nil

        stopUpdatingLocation()
        stopUpdatingHeading()

        logInfo("Stopped location service updates")
    }

    func foreground() {
        if requireNavigationAccuracy {
            desiredAccuracy = kCLLocationAccuracyBestForNavigation
            distanceFilter = kCLDistanceFilterNone
        } else {
            desiredAccuracy = defaultAccuracy
            distanceFilter = defaultDistanceFilter
        }
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

        UIApplication.shared.isIdleTimerDisabled = true

        startUpdatingHeading()
    }

    func disableNavigationAccuracy() {
        requireNavigationAccuracy = false
        desiredAccuracy = defaultAccuracy

        UIApplication.shared.isIdleTimerDisabled = false

        stopUpdatingHeading()
    }

    // MARK: Location + heading resolution

    func resolveCurrentLocationAndHeading(onResolved: @escaping OnLocationAndHeadingResolved) {
        foreground()
        resolveCurrentLocation { [weak self] location in
            self?.resolveCurrentHeading { heading in
                onResolved(location, heading)
            }
        }
    }

    // MARK: Location resolution

    func resolveCurrentLocation(_ durableKey: String? = nil, allowCachedLocation: Bool = false, onResolved: @escaping OnLocationResolved) {
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

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last, location.isAccurate {
            lastAccurateLocationDate = Date()
            locationResolved(location)
        } else if staleLocation {
            if let location = locations.last, location.isAccurateForForcedLocationUpdate {
                lastAccurateLocationDate = Date()
                locationResolved(location)
            }
        }
    }

    func removeOnLocationResolvedDurableCallback(_ key: String) {
        let callback = onLocationResolvedDurableCallbacks[key]
        if callback != nil {
            onLocationResolvedDurableCallbacks.removeValue(forKey: key)
        }
    }

    fileprivate func locationResolved(_ location: CLLocation) {
        logInfo("Resolved current location: \(location)")

        currentLocation = location

        DispatchQueue.global(qos: DispatchQoS.default.qosClass).async { [weak self] in
            for region in (self?.regions)! {
                if region.contains(location.coordinate) {
                    if let callbacks = self?.geofenceCallbacks[region.identifier] {
                        if let callback = callbacks["didEnterRegion"] {
                            if let callbackCounts = self?.geofenceCallbackCounts[region.identifier] {
                                let didEnterRegionCallCount = callbackCounts["didEnterRegion"] ?? 0
                                let didExitRegionCallCount = callbackCounts["didExitRegion"] ?? 0
                                if didEnterRegionCallCount > didExitRegionCallCount {
                                    logWarn("Not invoking didEnterRegion callback without first exiting")
                                    return
                                }
                                self?.geofenceCallbackCounts[region.identifier]?["didEnterRegion"] = didEnterRegionCallCount + 1
                            }
                            callback()
                        }
                    }
                }
            }
        }

        while onLocationResolvedCallbacks.count > 0 {
            let callback = onLocationResolvedCallbacks.remove(at: 0)
            callback(location)
        }

        for callback in onLocationResolvedDurableCallbacks.values {
            callback(location)
        }
    }

    // MARK: Heading resolution

    func resolveCurrentHeading(_ onResolved: @escaping OnHeadingResolved) {
        resolveCurrentHeading(onResolved, durableKey: nil)
    }

    func resolveCurrentHeading(_ onResolved: @escaping OnHeadingResolved, allowCachedHeading: Bool) {
        resolveCurrentHeading(onResolved, durableKey: nil, allowCachedHeading: allowCachedHeading)
    }

    func resolveCurrentHeading(_ onResolved: @escaping OnHeadingResolved, durableKey: String?, allowCachedHeading: Bool = false) {
        if isSimulator() {
            logInfo("Returning simulated heading details; simulator does not support heading")
            onResolved(SimulatedHeading())
            return
        }

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

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if abs(newHeading.timestamp.timeIntervalSinceNow) < 1.0 && newHeading.headingAccuracy >= 0.0 {
            headingResolved(newHeading)
        }
    }

    func removeOnHeadingResolvedDurableCallback(_ key: String) {
        let callback = onHeadingResolvedDurableCallbacks[key]
        if callback != nil {
            onHeadingResolvedDurableCallbacks.removeValue(forKey: key)
        }
    }

    fileprivate func headingResolved(_ heading: CLHeading) {
        logInfo("Resolved current heading: \(heading)")
        currentHeading = heading

        while onHeadingResolvedCallbacks.count > 0 {
            let callback = onHeadingResolvedCallbacks.remove(at: 0)
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

    func monitorRegion(_ region: CLCircularRegion, onDidEnterRegion: @escaping VoidBlock, onDidExitRegion: @escaping VoidBlock) {
        monitorRegionWithCircularOverlay(MKCircle(center: region.center, radius: region.radius),
                                         identifier: region.identifier,
                                         onDidEnterRegion: onDidEnterRegion,
                                         onDidExitRegion: onDidExitRegion)
    }

    func monitorRegionWithCircularOverlay(_ overlay: MKCircle, identifier: String, onDidEnterRegion: @escaping VoidBlock, onDidExitRegion: @escaping VoidBlock) {
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            return
        }

        var radius = overlay.radius
        if radius > maximumRegionMonitoringDistance {
            radius = maximumRegionMonitoringDistance
        }

        var callbacks = geofenceCallbacks[identifier]
        if callbacks == nil {
            callbacks = [String: VoidBlock]()

        }
        callbacks!["didEnterRegion"] = onDidEnterRegion
        callbacks!["didExitRegion"] = onDidExitRegion

        var callbackCounts = geofenceCallbackCounts[identifier]
        if callbackCounts == nil {
            callbackCounts = [String: Int]()
        }
        callbackCounts!["didEnterRegion"] = 0
        callbackCounts!["didExitRegion"] = 0

        geofenceCallbacks[identifier] = callbacks
        geofenceCallbackCounts[identifier] = callbackCounts

        let region = CLCircularRegion(center: overlay.coordinate, radius: radius, identifier: identifier)
        regions.append(region)
    }

    func unregisterRegionMonitor(_ identifier: String) {
        regionMonitorModificationQueue.async { [weak self] in
            for region in (self?.regions)! {
                if region.identifier == identifier {
                    self?.geofenceCallbacks.removeValue(forKey: region.identifier)
                    self?.geofenceCallbackCounts.removeValue(forKey: region.identifier)
                    self?.regions.removeObject(region)
                    break
                }
            }
        }
    }

    func unregisterRegionMonitors() {
        if regions.count > 0 {
            for region in regions {
                geofenceCallbacks.removeValue(forKey: region.identifier)
            }

            regions = [CLCircularRegion]()
        }
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        logInfo("Started monitoring region \(region)")
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let callbacks = geofenceCallbacks[region.identifier] {
            if let callback = callbacks["didEnterRegion"] {
                if let callbackCounts = geofenceCallbackCounts[region.identifier] {
                    let didEnterRegionCallCount = callbackCounts["didEnterRegion"] ?? 0
                    let didExitRegionCallCount = callbackCounts["didExitRegion"] ?? 0
                    if didEnterRegionCallCount > didExitRegionCallCount {
                        logWarn("Not invoking didEnterRegion callback without first exiting")
                        return
                    }
                    geofenceCallbackCounts[region.identifier]?["didEnterRegion"] = didEnterRegionCallCount + 1
                }
                callback()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let callbacks = geofenceCallbacks[region.identifier] {
            if let callback = callbacks["didExitRegion"] {
                if let callbackCounts = geofenceCallbackCounts[region.identifier] {
                    let didEnterRegionCallCount = callbackCounts["didEnterRegion"] ?? 0
                    let didExitRegionCallCount = callbackCounts["didExitRegion"] ?? 0
                    if didExitRegionCallCount != didEnterRegionCallCount - 1 {
                        logWarn("Not invoking didExitRegion callback without first entering")
                        return
                    }
                    geofenceCallbackCounts[region.identifier]?["didExitRegion"] = didExitRegionCallCount + 1
                }
                callback()
            }
        }
    }

    func reverseGeocodeLocation(_ location: CLLocation, onResolved: @escaping OnReverseGeocodeResolved) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(self.location!) { (placemarks, error) in
            if let placemarks = placemarks {
                if placemarks.count > 0 {
                    onResolved(placemarks.first!)
                }
            }
        }
    }
}
