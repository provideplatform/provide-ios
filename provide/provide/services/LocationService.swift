//
//  LocationService.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnHeadingResolved = (CLHeading) -> Void
typealias OnLocationResolved = (CLLocation) -> Void
typealias OnLocationAndHeadingResolved = (CLLocation, CLHeading) -> Void
typealias OnReverseGeocodeResolved = (CLPlacemark) -> Void

class LocationService: CLLocationManager, CLLocationManagerDelegate {
    static let shared = LocationService()

    let defaultAccuracy = kCLLocationAccuracyBest
    let defaultDistanceFilter = kCLDistanceFilterNone

    private let regionMonitorModificationQueue = DispatchQueue(label: "api.regionMonitorModificationQueue", attributes: [])

    private var currentHeading: CLHeading!
    private(set) var currentLocation: CLLocation!

    private var intervalSinceLastAccurateLocation: TimeInterval? {
        if let locationServiceStartedDate = locationServiceStartedDate, let lastAccurateLocationDate = lastAccurateLocationDate {
            return lastAccurateLocationDate.timeIntervalSince(locationServiceStartedDate)
        }
        return nil
    }

    private var locationServiceStartedDate: Date!
    private var lastAccurateLocationDate: Date!

    private var geofenceCallbacks = [String: [String: VoidBlock]]()
    private var geofenceCallbackCounts = [String: [String: Int]]()
    private var onManagerAuthorizedCallbacks = [VoidBlock]()

    private var onHeadingResolvedCallbacks = [OnHeadingResolved]()
    private var onHeadingResolvedDurableCallbacks = [String: OnHeadingResolved]()

    private var onLocationResolvedCallbacks = [OnLocationResolved]()
    private var onLocationResolvedDurableCallbacks = [String: OnLocationResolved]()

    private var onLocationAndHeadingResolvedCallbacks = [OnLocationAndHeadingResolved]()
    private var onLocationAndHeadingResolvedDurableCallbacks = [String: OnLocationAndHeadingResolved]()

    private var requireNavigationAccuracy = false

    private var regions = [CLCircularRegion]()

    private var staleLocation: Bool {
        if intervalSinceLastAccurateLocation != nil && abs(intervalSinceLastAccurateLocation!) >= 15.0 {
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

    // MARK: Authorization

    func requireAuthorization(_ callback: @escaping VoidBlock) {
        let status = CLLocationManager.authorizationStatus()
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            callback()
        } else if status == .notDetermined {
            KTNotificationCenter.post(name: .ApplicationWillRequestLocationAuthorization)
            onManagerAuthorizedCallbacks.append(callback)
            requestWhenInUseAuthorization()
            //requestAlwaysAuthorization()
        } else if status == .denied {
            KTNotificationCenter.post(name: .ApplicationUserDeniedLocationServices)
            logWarn("Use has denied access to location services")
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            while onManagerAuthorizedCallbacks.count > 0 {
                let callback = onManagerAuthorizedCallbacks.remove(at: 0)
                callback()
            }
        } else if status == .notDetermined {
            // TODO
        } else if status == .denied {
            KTNotificationCenter.post(name: .ApplicationUserDeniedLocationServices)
            logWarn("Use has denied access to location services")
        }
    }

    // MARK: Start/stop location updates

    func start() {
        if locationServiceStartedDate == nil {
            locationServiceStartedDate = Date()

            startUpdatingLocation()
            startUpdatingHeading()

            logmoji("✳️", "Started location service updates")
        }
    }

    func stop() {
        if locationServiceStartedDate != nil {
            disableNavigationAccuracy()

            stopUpdatingLocation()
            stopUpdatingHeading()

            locationServiceStartedDate = nil

            logmoji("🛑", "Stopped location service updates")
        }
    }

    private func foreground() {
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

    func enableNavigationAccuracy(disableIdleTimer: Bool = true) {
        requireNavigationAccuracy = true
        desiredAccuracy = kCLLocationAccuracyBestForNavigation

        UIApplication.shared.isIdleTimerDisabled = disableIdleTimer

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
        if let durableKey = durableKey {
            onLocationResolvedDurableCallbacks[durableKey] = onResolved
        } else if !allowCachedLocation {
            onLocationResolvedCallbacks.append(onResolved)
        }

        if allowCachedLocation && currentLocation != nil {
            onResolved(currentLocation)
        } else {
            foreground()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var location: CLLocation?
        location = locations.first { location -> Bool in
            return location.isAccurate
        }

        if location == nil && staleLocation {
            location = locations.first { location -> Bool in
                return location.isAccurateForForcedLocationUpdate
            }
        }

        if let location = location {
            lastAccurateLocationDate = Date()
            locationResolved(location)
        }
    }

    func removeOnLocationResolvedDurableCallback(_ key: String) {
        let callback = onLocationResolvedDurableCallbacks[key]
        if callback != nil {
            onLocationResolvedDurableCallbacks.removeValue(forKey: key)
        }
    }

    private func locationResolved(_ location: CLLocation) {
        logmoji("🌎", "Location: \(location)")

        currentLocation = location

        DispatchQueue.global(qos: DispatchQoS.default.qosClass).async { [weak self] in
            for region in self?.regions ?? [] {
                if region.contains(location.coordinate) {
                    if let callbacks = self?.geofenceCallbacks[region.identifier], let callback = callbacks["didEnterRegion"] {
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

        while onLocationResolvedCallbacks.count > 0 {
            let callback = onLocationResolvedCallbacks.remove(at: 0)
            callback(location)
        }

        for callback in onLocationResolvedDurableCallbacks.values {
            callback(location)
        }
    }

    // MARK: Heading resolution

    private func resolveCurrentHeading(_ onResolved: @escaping OnHeadingResolved) {
        resolveCurrentHeading(onResolved, durableKey: nil)
    }

    private func _resolveCurrentHeading(_ onResolved: @escaping OnHeadingResolved, allowCachedHeading: Bool) {
        resolveCurrentHeading(onResolved, durableKey: nil, allowCachedHeading: allowCachedHeading)
    }

    private func resolveCurrentHeading(_ onResolved: @escaping OnHeadingResolved, durableKey: String?, allowCachedHeading: Bool = false) {
        if isSimulator() {
            // logInfo("Returning simulated heading details; simulator does not support heading")
            onResolved(SimulatedHeading())
            return
        }

        if let currentHeading = currentHeading, allowCachedHeading {
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

    private func headingResolved(_ heading: CLHeading) {
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
        monitorRegionWithCircularOverlay(MKCircle(center: region.center, radius: region.radius), identifier: region.identifier, onDidEnterRegion: onDidEnterRegion, onDidExitRegion: onDidExitRegion)
    }

    func monitorRegionWithCircularOverlay(_ overlay: MKCircle, identifier: String, onDidEnterRegion: @escaping VoidBlock, onDidExitRegion: @escaping VoidBlock) {
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            return
        }

        var radius = overlay.radius
        if radius > maximumRegionMonitoringDistance {
            radius = maximumRegionMonitoringDistance
        }

        var callbacks = geofenceCallbacks[identifier] ?? [String: VoidBlock]()
        callbacks["didEnterRegion"] = onDidEnterRegion
        callbacks["didExitRegion"] = onDidExitRegion

        var callbackCounts = geofenceCallbackCounts[identifier] ?? [String: Int]()
        callbackCounts["didEnterRegion"] = 0
        callbackCounts["didExitRegion"] = 0

        geofenceCallbacks[identifier] = callbacks
        geofenceCallbackCounts[identifier] = callbackCounts

        let region = CLCircularRegion(center: overlay.coordinate, radius: radius, identifier: identifier)
        regions.append(region)

        AnalyticsService.shared.track("Registered Region Monitor",
                                      properties: ["user_id": currentUser.id,
                                                   "identifier": region.identifier,
                                                   "center_latitude": region.center.latitude,
                                                   "center_longitude": region.center.longitude,
                                                   "radius": region.radius,
                                                   ])
    }

    func unregisterRegionMonitor(_ identifier: String) {
        regionMonitorModificationQueue.async { [weak self] in
            for region in (self?.regions)! where region.identifier == identifier {
                self?.geofenceCallbacks.removeValue(forKey: region.identifier)
                self?.geofenceCallbackCounts.removeValue(forKey: region.identifier)
                self?.regions.removeObject(region)
                AnalyticsService.shared.track("Unregistered Region Monitor",
                                              properties: ["user_id": currentUser.id,
                                                           "identifier": region.identifier,
                                                           ])
                break
            }
        }
    }

    private func _unregisterRegionMonitors() {
        if regions.count > 0 {
            for region in regions {
                geofenceCallbacks.removeValue(forKey: region.identifier)
            }

            regions = []
        }
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        logmoji("⭕️", "\(#function)")
        logmoji("⭕️", "Started monitoring region \(region)")
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let callbacks = geofenceCallbacks[region.identifier], let callback = callbacks["didEnterRegion"] {
            if let callbackCounts = geofenceCallbackCounts[region.identifier] {
                let didEnterRegionCallCount = callbackCounts["didEnterRegion"] ?? 0
                let didExitRegionCallCount = callbackCounts["didExitRegion"] ?? 0
                if didEnterRegionCallCount > didExitRegionCallCount {
                    logWarn("Not invoking didEnterRegion callback without first exiting")
                    AnalyticsService.shared.track("Not invoking didEnterRegion callback without first exiting",
                                                  properties: ["user_id": currentUser.id,
                                                               "identifier": region.identifier,
                                                               ])
                    return
                }
                geofenceCallbackCounts[region.identifier]?["didEnterRegion"] = didEnterRegionCallCount + 1
            }
            callback()
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let callbacks = geofenceCallbacks[region.identifier], let callback = callbacks["didExitRegion"] {
            if let callbackCounts = geofenceCallbackCounts[region.identifier] {
                let didEnterRegionCallCount = callbackCounts["didEnterRegion"] ?? 0
                let didExitRegionCallCount = callbackCounts["didExitRegion"] ?? 0
                if didExitRegionCallCount != didEnterRegionCallCount - 1 {
                    logWarn("Not invoking didExitRegion callback without first entering")
                    AnalyticsService.shared.track("Not invoking didExitRegion callback without first exiting",
                                                  properties: ["user_id": currentUser.id,
                                                               "identifier": region.identifier,
                                                               ])
                    return
                }
                geofenceCallbackCounts[region.identifier]?["didExitRegion"] = didExitRegionCallCount + 1
            }
            callback()
        }
    }

    func reverseGeocodeLocation(_ location: CLLocation, onResolved: @escaping OnReverseGeocodeResolved) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(self.location!) { placemarks, error in
            if let placemarks = placemarks, placemarks.count > 0 {
                onResolved(placemarks.first!)
            }
        }
    }
}
