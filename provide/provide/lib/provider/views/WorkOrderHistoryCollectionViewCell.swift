//
//  WorkOrderHistoryCollectionViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 11/6/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class WorkOrderHistoryCollectionViewCell: UICollectionViewCell, MKMapViewDelegate {

    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var mapView: RouteMapView!

    @IBOutlet private weak var detailsContainerView: UIView!
    @IBOutlet private weak var statusBackgroundView: UIView!
    @IBOutlet private weak var timestampLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!

    private var gravatarImageView: RFGravatarImageView!

    private var timer: NSTimer!

    var workOrder: WorkOrder! {
        didSet {
            addBorder(1.0, color: UIColor.lightGrayColor())
            roundCorners(4.0)

            contentView.backgroundColor = UIColor.clearColor()
            detailsContainerView.backgroundColor = UIColor.clearColor()

            mapView.showsUserLocation = false
            mapView.removeAnnotations()
            mapView.removeOverlays()

            if let workOrder = workOrder {
                if let workOrderProviders = workOrder.workOrderProviders {
                    for workOrderProvider in workOrderProviders {
                        if let checkinsPolyline = workOrderProvider.checkinsPolyline {
                            mapView.addOverlay(checkinsPolyline, level: .AboveRoads)

                            let edgePadding = UIEdgeInsets(top: 40.0, left: 0.0, bottom: 10.0, right: 0.0)

                            if checkinsPolyline.pointCount > 0 {
                                mapView.setVisibleMapRect(checkinsPolyline.boundingMapRect, edgePadding: edgePadding, animated: false)
                            } else {
                                mapView.setCenterCoordinate(workOrder.coordinate, zoomLevel: 12, animated: false)
                            }
                        }
                    }
                }


                mapView.addAnnotation(workOrder.annotation)

                mapView.alpha = 1.0

                statusBackgroundView.backgroundColor = workOrder.statusColor
                statusBackgroundView.frame = bounds
                statusBackgroundView.alpha = 0.9

                //            if let profileImageUrl = workOrder.providerOriginAssignment.provider.profileImageUrl {
                //                avatarImageView.contentMode = .ScaleAspectFit
                //                avatarImageView.sd_setImageWithURL(profileImageUrl) { image, error, imageCacheType, url in
                //                    self.bringSubviewToFront(self.avatarImageView)
                //                    self.avatarImageView.makeCircular()
                //                    self.avatarImageView.alpha = 1.0
                //                    self.gravatarImageView?.alpha = 0.0
                //                }
                //            } else {
                //                let gravatarImageView = RFGravatarImageView(frame: avatarImageView.frame)
                //                gravatarImageView.email = route.providerOriginAssignment.provider.contact.email
                //                gravatarImageView.load { error in
                //                    gravatarImageView.makeCircular()
                //                    self.insertSubview(gravatarImageView, aboveSubview: self.avatarImageView)
                //                    self.avatarImageView.alpha = 0.0
                //                    gravatarImageView.alpha = 1.0
                //                }
                //            }

                if let timestamp = workOrder.humanReadableStartedAtTimestamp {
                    timestampLabel.text = timestamp.uppercaseString
                    timestampLabel.sizeToFit()
                } else if let timestamp = workOrder.humanReadableScheduledStartAtTimestamp {
                    timestampLabel.text = timestamp.uppercaseString
                    timestampLabel.sizeToFit()
                }

                if let duration = workOrder.humanReadableDuration {
                    durationLabel.text = duration.uppercaseString
                    durationLabel.sizeToFit()
                }

                if let status = workOrder.status {
                    statusLabel.text = status.uppercaseString

                    if status == "en_route" || status == "in_progress" {
                        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(WorkOrderHistoryCollectionViewCell.refresh), userInfo: nil, repeats: true)
                        timer.fire()
                    } else if workOrder.status == "scheduled" {
                        durationLabel.text = workOrder.scheduledStartAtDate.timeString
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

        contentView.backgroundColor = UIColor.clearColor()
        detailsContainerView.backgroundColor = UIColor.clearColor()

        mapView.alpha = 0.0
        mapView.removeAnnotations()
        mapView.removeOverlays()

        statusBackgroundView.backgroundColor = UIColor.clearColor()
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
        if let duration = workOrder.humanReadableDuration {
            durationLabel.text = duration.uppercaseString
            durationLabel.sizeToFit()
        }

        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseIn,
            animations: {
                let alpha = self.statusBackgroundView?.alpha == 0.0 ? 0.9 : 0.0
                self.statusBackgroundView?.alpha = CGFloat(alpha)
            },
            completion: { complete in
                
            }
        )
    }
}
