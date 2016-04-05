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
                if let activityIndicatorView = activityIndicatorView {
                    if comment.body == nil || comment.body.length == 0 {
                        activityIndicatorView.startAnimating()
                        bringSubviewToFront(activityIndicatorView)
                    }
                }

                if let imageAttachments = comment.attachments {
                    for attachment in imageAttachments {
                        attachmentPreviewImageView?.sd_setImageWithURL(attachment.url, placeholderImage: nil, completed: { image, error, cacheType, url in
                            if let attachmentPreviewImageView = self.attachmentPreviewImageView {
                                attachmentPreviewImageView.alpha = 1.0
                                self.bringSubviewToFront(attachmentPreviewImageView)
                            }
                            self.activityIndicatorView?.stopAnimating()
                        })
                    }
                } else {
                    self.activityIndicatorView?.stopAnimating()
                    self.attachmentPreviewImageView.alpha = 0.0
                }

                bodyTextView?.editable = false

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
                    var timestamp = "\(comment.createdAtDate.dayOfWeek), \(comment.createdAtDate.monthName) \(comment.createdAtDate.dayOfMonth), \(comment.createdAtDate.year)"
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
    @IBOutlet private weak var attachmentPreviewImageView: UIImageView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    override func prepareForReuse() {
        super.prepareForReuse()

        attachmentPreviewImageView?.alpha = 0.0
        attachmentPreviewImageView?.image = nil

        activityIndicatorView?.stopAnimating()
    }
}
