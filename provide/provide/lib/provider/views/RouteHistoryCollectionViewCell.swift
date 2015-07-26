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
    @IBOutlet private weak var timestampLabel: UILabel!

    private var gravatarImageView: RFGravatarImageView!

    var route: Route! {
        didSet {
            addBorder(1.0, color: UIColor.lightGrayColor())
            roundCorners(4.0)
            
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

            timestampLabel.text = "\(route.startAtDate.dayOfWeek), \(route.startAtDate.monthName) \(route.startAtDate.dayOfMonth) @ \(route.startAtDate.timeString!)"
            timestampLabel.sizeToFit()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        avatarImageView.image = nil
        avatarImageView.alpha = 0.0

        gravatarImageView?.image = nil
        gravatarImageView = nil

        timestampLabel.text = ""
    }
}
