//
//  RouteHistoryCollectionViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 7/26/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class RouteHistoryCollectionViewCell: UICollectionViewCell, MKMapViewDelegate {

    @IBOutlet fileprivate weak var avatarImageView: UIImageView!
    @IBOutlet fileprivate weak var mapView: RouteMapView!

    @IBOutlet fileprivate weak var detailsContainerView: UIView!
    @IBOutlet fileprivate weak var statusBackgroundView: UIView!
    @IBOutlet fileprivate weak var timestampLabel: UILabel!
    @IBOutlet fileprivate weak var durationLabel: UILabel!
    @IBOutlet fileprivate weak var statusLabel: UILabel!

    fileprivate var gravatarImageView: UIImageView!

    fileprivate var timer: Timer!

    var route: Route! {
        didSet {
            addBorder(1.0, color: UIColor.lightGray)
            roundCorners(4.0)

            contentView.backgroundColor = UIColor.clear
            detailsContainerView.backgroundColor = UIColor.clear

            mapView.showsUserLocation = false
            mapView.removeAnnotations()
            mapView.removeOverlays()

            for workOrder in route.workOrders {
                mapView.addAnnotation(workOrder.annotation)
            }

            for workOrder in route.workOrders {
                for workOrderProvider in workOrder.workOrderProviders {
                    if let checkinCoordinates = workOrderProvider.checkinCoordinates as? [[NSNumber]] {
                        var coords = [CLLocationCoordinate2D]()
                        for checkinCoordinate in checkinCoordinates {
                            let latitude = checkinCoordinate[0].doubleValue
                            let longitude = checkinCoordinate[1].doubleValue
                            coords.append(CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                        }
                        if coords.count > 0 {
                            let checkinsPolyline = MKPolyline(coordinates: &coords, count: coords.count)
                            mapView.add(checkinsPolyline, level: .aboveRoads)
                        }
                    }
                }
            }

            if mapView.overlays.count > 0 {
                var visibleRect = mapView.overlays.first!.boundingMapRect
                for overlay in mapView.overlays {
                    visibleRect = MKMapRectUnion(visibleRect, overlay.boundingMapRect)
                }
                mapView.setVisibleMapRect(visibleRect, animated: false)
            } else if route.workOrders.count > 0 {
                mapView.setCenterCoordinate(route.workOrders.first!.coordinate, zoomLevel: 12, animated: false)
            }

            mapView.alpha = 1.0

            statusBackgroundView.backgroundColor = route.statusColor
            statusBackgroundView.frame = bounds
            statusBackgroundView.alpha = 0.9

            if let profileImageUrl = route.providerOriginAssignment.provider.profileImageUrl {
                avatarImageView.contentMode = .scaleAspectFit
                avatarImageView.sd_setImage(with: profileImageUrl as URL) { image, error, imageCacheType, url in
                    self.bringSubview(toFront: self.avatarImageView)
                    self.avatarImageView.makeCircular()
                    self.avatarImageView.alpha = 1.0
                    self.gravatarImageView?.alpha = 0.0
                }
            } else {
//                let gravatarImageView = UIImageView(frame: avatarImageView.frame)
//                gravatarImageView.email = route.providerOriginAssignment.provider.contact.email
//                gravatarImageView.load { error in
//                    gravatarImageView.makeCircular()
//                    self.insertSubview(gravatarImageView, aboveSubview: self.avatarImageView)
//                    self.avatarImageView.alpha = 0.0
//                    gravatarImageView.alpha = 1.0
//                }
            }

            if let timestamp = route.humanReadableLoadingStartedAtTimestamp {
                timestampLabel.text = timestamp.uppercased()
                timestampLabel.sizeToFit()
            } else if let timestamp = route.humanReadableStartedAtTimestamp {
                timestampLabel.text = timestamp.uppercased()
                timestampLabel.sizeToFit()
            } else if let timestamp = route.humanReadableScheduledStartAtTimestamp {
                timestampLabel.text = timestamp.uppercased()
                timestampLabel.sizeToFit()
            }

            if let duration = route.humanReadableDuration {
                durationLabel.text = duration.uppercased()
                durationLabel.sizeToFit()
            }

            statusLabel.text = route.status.uppercased()
            statusLabel.sizeToFit()

            if route.status == "loading" || route.status == "in_progress" || route.status == "unloading" || route.status == "pending_completion" {
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(RouteHistoryCollectionViewCell.refresh), userInfo: nil, repeats: true)
                timer.fire()
            } else if route.status == "scheduled" {
                durationLabel.text = route.scheduledStartAtDate.timeString
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        contentView.backgroundColor = UIColor.clear
        detailsContainerView.backgroundColor = UIColor.clear

        mapView.alpha = 0.0
        mapView.removeAnnotations()
        mapView.removeOverlays()

        statusBackgroundView.backgroundColor = UIColor.clear
        statusBackgroundView.alpha = 0.9

        avatarImageView.image = nil
        avatarImageView.alpha = 0.0

        gravatarImageView?.image = nil
        gravatarImageView = nil

        timestampLabel.text = ""
        durationLabel.text = ""
        statusLabel.text = ""

        timer?.invalidate()
    }

    func refresh() {
        if let duration = route.humanReadableDuration {
            durationLabel.text = duration.uppercased()
            durationLabel.sizeToFit()
        }

        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn,
            animations: {
                let alpha = self.statusBackgroundView?.alpha == 0.0 ? 0.9 : 0.0
                self.statusBackgroundView?.alpha = CGFloat(alpha)
            },
            completion: { complete in

            }
        )
    }
}
