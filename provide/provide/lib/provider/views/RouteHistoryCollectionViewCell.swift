//
//  RouteHistoryCollectionViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 7/26/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class RouteHistoryCollectionViewCell: UICollectionViewCell {

    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var mapView: MapView!

    @IBOutlet private weak var detailsContainerView: UIView!
    @IBOutlet private weak var statusBackgroundView: UIView!
    @IBOutlet private weak var timestampLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!

    private var gravatarImageView: RFGravatarImageView!

    private var timer: NSTimer!

    var route: Route! {
        didSet {
            addBorder(1.0, color: UIColor.lightGrayColor())
            roundCorners(4.0)

            contentView.backgroundColor = UIColor.clearColor()
            detailsContainerView.backgroundColor = UIColor.clearColor()

            statusBackgroundView.backgroundColor = route.statusColor
            statusBackgroundView.frame = bounds
            statusBackgroundView.alpha = 0.9

            if let profileImageUrl = route.providerOriginAssignment.provider.profileImageUrl {
                avatarImageView.sd_setImageWithURL(profileImageUrl, completed: { (image, error, imageCacheType, url) -> Void in
                    self.bringSubviewToFront(self.avatarImageView)
                    self.avatarImageView.makeCircular()
                    self.avatarImageView.alpha = 1.0
                    self.gravatarImageView?.alpha = 0.0
                })
            } else {
                let gravatarImageView = RFGravatarImageView(frame: avatarImageView.frame)
                gravatarImageView.email = route.providerOriginAssignment.provider.contact.email
                gravatarImageView.load { error in
                    gravatarImageView.makeCircular()
                    self.insertSubview(gravatarImageView, aboveSubview: self.avatarImageView)
                    self.avatarImageView.alpha = 0.0
                    gravatarImageView.alpha = 1.0
                }
            }

            if let timestamp = route.humanReadableStartAtTimestamp {
                timestampLabel.text = timestamp.uppercaseString
                timestampLabel.sizeToFit()
            }

            if let duration = route.humanReadableDuration {
                durationLabel.text = duration.uppercaseString
                durationLabel.sizeToFit()
            }

            statusLabel.text = route.status.uppercaseString
            statusLabel.sizeToFit()

            if route.status == "loading" || route.status == "in_progress" || route.status == "unloading" {
                timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "refresh", userInfo: nil, repeats: true)
                timer.fire()
            } else if route.status == "scheduled" {
                durationLabel.text = route.startAtDate.timeString
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        contentView.backgroundColor = UIColor.clearColor()
        detailsContainerView.backgroundColor = UIColor.clearColor()

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
        if let duration = route.humanReadableDuration {
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