//
//  ProductionTableViewCell.swift
//  startrack
//
//  Created by Kyle Thomas on 9/7/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class ProductionTableViewCell: UITableViewCell {

    @IBOutlet private weak var avatarImageView: UIImageView!

    @IBOutlet private weak var detailsContainerView: UIView!
    @IBOutlet private weak var statusBackgroundView: UIView!
    @IBOutlet private weak var timestampLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!

    private var gravatarImageView: RFGravatarImageView!

    private var timer: NSTimer!

    var production: Production! {
        didSet {
            addBorder(1.0, color: UIColor.lightGrayColor())
            roundCorners(4.0)

            contentView.backgroundColor = UIColor.clearColor()
            detailsContainerView.backgroundColor = UIColor.clearColor()

//            statusBackgroundView.backgroundColor = production.statusColor
//            statusBackgroundView.frame = bounds
//            statusBackgroundView.alpha = 0.9

//            if let profileImageUrl = production.providerOriginAssignment.provider.profileImageUrl {
//                avatarImageView.contentMode = .ScaleAspectFit
//                avatarImageView.sd_setImageWithURL(profileImageUrl) { image, error, imageCacheType, url in
//                    self.bringSubviewToFront(self.avatarImageView)
//                    self.avatarImageView.makeCircular()
//                    self.avatarImageView.alpha = 1.0
//                    self.gravatarImageView?.alpha = 0.0
//                }
//            } else {
//                let gravatarImageView = RFGravatarImageView(frame: avatarImageView.frame)
//                gravatarImageView.email = production.providerOriginAssignment.provider.contact.email
//                gravatarImageView.load { error in
//                    gravatarImageView.makeCircular()
//                    self.insertSubview(gravatarImageView, aboveSubview: self.avatarImageView)
//                    self.avatarImageView.alpha = 0.0
//                    gravatarImageView.alpha = 1.0
//                }
//            }

//            if let timestamp = production.humanReadableLoadingStartedAtTimestamp {
//                timestampLabel.text = timestamp.uppercaseString
//                timestampLabel.sizeToFit()
//            } else if let timestamp = route.humanReadableStartedAtTimestamp {
//                timestampLabel.text = timestamp.uppercaseString
//                timestampLabel.sizeToFit()
//            } else if let timestamp = route.humanReadableScheduledStartAtTimestamp {
//                timestampLabel.text = timestamp.uppercaseString
//                timestampLabel.sizeToFit()
//            }

//            if let duration = route.humanReadableDuration {
//                durationLabel.text = duration.uppercaseString
//                durationLabel.sizeToFit()
//            }
//
//            statusLabel.text = route.status.uppercaseString
//            statusLabel.sizeToFit()
//
//            if route.status == "loading" || route.status == "in_progress" || route.status == "unloading" || route.status == "pending_completion" {
//                timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "refresh", userInfo: nil, repeats: true)
//                timer.fire()
//            } else if route.status == "scheduled" {
//                durationLabel.text = route.scheduledStartAtDate.timeString
//            }
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
//        if let duration = production.humanReadableDuration {
//            durationLabel.text = duration.uppercaseString
//            durationLabel.sizeToFit()
//        }

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
