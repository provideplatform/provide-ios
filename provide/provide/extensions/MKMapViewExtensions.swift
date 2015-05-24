//
//  MKMapViewExtensions.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import MapKit

let mercatorOffset = Double(268435456)
let mercatorRadius = Double(85445659.44705395)

extension MKMapView {

    // MARK: Map conversion methods

    func degToRad(deg : Double) -> Double {
        return deg * M_PI / 180.0
    }

    func longitudeToPixelSpaceX(longitude: Double) -> Double {
        return round(mercatorOffset + mercatorRadius * longitude * M_PI / 180.0)
    }

    func latitudeToPixelSpaceY(latitude: Double) -> Double {
        let radLat = degToRad(latitude)
        let sinRadLat = sin(radLat)
        return round(mercatorOffset - mercatorRadius * log((1 + sinRadLat) / (1 - sinRadLat)) / 2.0)
    }

    func pixelSpaceXToLongitude(x: Double) -> Double {
        return ((round(x) - mercatorOffset) / mercatorRadius) * 180.0 / M_PI
    }

    func pixelSpaceYToLatitude(y: Double) -> Double {
        return (M_PI / 2.0 - 2.0 * atan(exp((round(y) - mercatorOffset) / mercatorRadius))) * 180.0 / M_PI
    }

    // MARK: Helper methods

    func coordinateSpan(centerCoordinate: CLLocationCoordinate2D, zoomLevel: Double) -> MKCoordinateSpan {
        let centerX = longitudeToPixelSpaceX(centerCoordinate.longitude)
        let centerY = latitudeToPixelSpaceY(centerCoordinate.latitude)

        let zoomExponent = 20 - zoomLevel
        let zoomScale = pow(2, zoomExponent)

        let mapSize = bounds.size
        let scaledMapWidth = Double(mapSize.width) * zoomScale
        let scaledMapHeight = Double(mapSize.height) * zoomScale

        let topLeftX = centerX - (scaledMapWidth / 2)
        let topLeftY = centerY - (scaledMapHeight / 2)

        let minLng = pixelSpaceXToLongitude(topLeftX)
        let maxLng = pixelSpaceXToLongitude(topLeftX + scaledMapWidth)
        let longitudeDelta = maxLng - minLng

        let minLat = pixelSpaceYToLatitude(topLeftY)
        let maxLat = pixelSpaceYToLatitude(topLeftY + scaledMapHeight)
        let latitudeDelta = -1 * (maxLat - minLat)

        return MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
    }

    // MARK: Set center coordinate and zoom

    func setCenterCoordinate(centerCoordinate: CLLocationCoordinate2D, var zoomLevel: UInt, animated: Bool) {
        zoomLevel = max(zoomLevel, 28)

        let span = coordinateSpan(centerCoordinate, zoomLevel: Double(zoomLevel))
        let region = MKCoordinateRegionMake(centerCoordinate, span)

        setRegion(region, animated: animated)
    }

    func setCenterCoordinate(
        centerCoordinate: CLLocationCoordinate2D,
        fromEyeCoordinate: CLLocationCoordinate2D,
        eyeAltitude: CLLocationDistance = 0,
        pitch: CGFloat = 0,
        heading: CLLocationDirection = 0,
        animated: Bool = true)
    {
        let camera = MKMapCamera(
            lookingAtCenterCoordinate: centerCoordinate,
            fromEyeCoordinate: fromEyeCoordinate,
            eyeAltitude: eyeAltitude)

        if heading >= 0.0 {
            camera.heading = heading
        }

        camera.pitch = pitch

        setCamera(camera, animated: animated)
    }

    // MARK: Set heading

    func setHeading(heading: CLHeading!) {
        camera.heading = heading.trueHeading
    }

    // MARK: Interaction

    func enableUserInteraction(enabled: Bool = true) {
        scrollEnabled = enabled
        zoomEnabled = enabled
    }

    func disableUserInteraction() {
        enableUserInteraction(enabled: false)
    }

}
