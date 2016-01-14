//
//  CommentCollectionViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 12/16/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class CommentCollectionViewCell: UICollectionViewCell {

    var comment: Comment! {
        didSet {
            if let comment = comment {
                nameLabel?.text = comment.user.name
                bodyTextView?.text = comment.body

                if let imageUrl = comment.user.profileImageUrl {
                    imageView.contentMode = .ScaleAspectFit
                    imageView.sd_setImageWithURL(imageUrl, completed: { image, error, cacheType, url in
                        self.contentView.bringSubviewToFront(self.imageView)
                        self.imageView.makeCircular()

                        self.imageView.alpha = 1.0
                    })
                }

                let date = comment.createdAtDate
                let secondsOld = abs(date.timeIntervalSinceNow)
                if secondsOld < 60 {
                    timestampLabel?.text = "Just now"
                } else if secondsOld < 3600 {
                    timestampLabel?.text = "\(NSString(format: "%.0f", ceil(secondsOld / 60.0))) minutes ago"
                } else if secondsOld < 86400 {
                    timestampLabel?.text = "\(NSString(format: "%.0f", ceil(secondsOld / 60.0 / 60.0))) hours ago"
                } else {
                    var timestamp = "\(comment.createdAtDate.dayOfWeek), \(comment.createdAtDate.month) \(comment.createdAtDate.dayOfMonth)"
                    if let timeString = comment.createdAtDate.timeString {
                        timestamp = "\(timestamp) at \(timeString)"
                    }
                    timestampLabel?.text = timestamp
                }
            }
        }
    }

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var timestampLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var bodyTextView: UITextView!

    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
