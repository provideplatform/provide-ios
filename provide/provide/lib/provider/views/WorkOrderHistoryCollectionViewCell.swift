//
//  WorkOrderHistoryCollectionViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 11/6/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class WorkOrderHistoryCollectionViewCell: UICollectionViewCell, MKMapViewDelegate {

    @IBOutlet private weak var profileImageView: ProfileImageView!
    @IBOutlet private weak var mapView: RouteMapView!

    @IBOutlet private weak var detailsContainerView: UIView!
    @IBOutlet private weak var statusBackgroundView: UIView!
    @IBOutlet private weak var timestampLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!

    private var gravatarImageView: UIImageView?

    private var timer: Timer?

    var workOrder: WorkOrder! {
        didSet {
            addBorder(1.0, color: .lightGray)
            roundCorners(4.0)

            contentView.backgroundColor = .clear
            detailsContainerView.backgroundColor = .clear

            mapView.showsUserLocation = false
            mapView.removeAnnotations()
            mapView.removeOverlays()

            if let workOrderProviders = workOrder?.workOrderProviders {
                for workOrderProvider in workOrderProviders {
                    if let checkinsPolyline = workOrderProvider.checkinsPolyline {
                        mapView.add(checkinsPolyline, level: .aboveRoads)

                        let edgePadding = UIEdgeInsets(top: 40.0, left: 0.0, bottom: 10.0, right: 0.0)

                        if checkinsPolyline.pointCount > 0 {
                            mapView.setVisibleMapRect(checkinsPolyline.boundingMapRect, edgePadding: edgePadding, animated: false)
                        } else {
                            mapView.setCenterCoordinate(workOrder.coordinate!, zoomLevel: 12, animated: false)
                        }
                    }
                }

                mapView.addAnnotation(workOrder.annotationPin)

                mapView.onMapRevealed = { [weak self] in
                    self?.mapView.alpha = 1.0
                }

                statusBackgroundView.frame = bounds
//                statusBackgroundView.backgroundColor = workOrder.statusColor
//                statusBackgroundView.alpha = 0.9

                if let profileImageUrl = workOrder?.providerProfileImageUrl {
                    profileImageView.setImageWithUrl(profileImageUrl) { [weak self] in
                        if let strongSelf = self {
                            strongSelf.bringSubview(toFront: strongSelf.profileImageView)
                            strongSelf.profileImageView.makeCircular()
                            strongSelf.profileImageView.alpha = 1.0
                        }
                    }
                }

                if let timestamp = workOrder.humanReadableStartedAtTimestamp {
                    timestampLabel.text = timestamp.uppercased()
                    timestampLabel.sizeToFit()
                } else if let timestamp = workOrder.humanReadableScheduledStartAtTimestamp {
                    timestampLabel.text = timestamp.uppercased()
                    timestampLabel.sizeToFit()
                }

                if let duration = workOrder.humanReadableDuration {
                    durationLabel.text = duration.uppercased()
                    durationLabel.sizeToFit()
                }

                priceLabel.text = ""
                if let humanReadablePrice = workOrder.humanReadablePrice {
                    priceLabel.text = humanReadablePrice
                }

                let status = workOrder.status
                if status != "none" {
                    statusLabel.text = status.uppercased()

                    if status == "en_route" || status == "in_progress" {
                        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
                        timer?.fire()
                    } else if workOrder.status == "scheduled" {
                        durationLabel.text = workOrder.scheduledStartAtDate?.timeString
                    }
                } else {
                    statusLabel.text = ""

                    timer?.invalidate()
                    timer = nil
                }

                statusLabel.sizeToFit()
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        contentView.backgroundColor = .clear
        detailsContainerView.backgroundColor = .clear

        mapView.alpha = 0.0
        mapView.removeAnnotations()
        mapView.removeOverlays()

        statusBackgroundView.backgroundColor = .clear
        statusBackgroundView.alpha = 0.9

        profileImageView.image = nil
        profileImageView.alpha = 0.0

        gravatarImageView?.image = nil
        gravatarImageView = nil

        timestampLabel.text = ""
        durationLabel.text = ""
        statusLabel.text = ""
        priceLabel.text = ""

        timer?.invalidate()
    }

    @objc func refresh() {
        if let duration = workOrder.humanReadableDuration {
            durationLabel.text = duration.uppercased()
            durationLabel.sizeToFit()
        }

        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: {
            let alpha = self.statusBackgroundView?.alpha == 0.0 ? 0.9 : 0.0
            self.statusBackgroundView?.alpha = CGFloat(alpha)
        })
    }
}
