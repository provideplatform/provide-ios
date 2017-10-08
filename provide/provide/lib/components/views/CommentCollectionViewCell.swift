//
//  CommentCollectionViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 12/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class CommentCollectionViewCell: UICollectionViewCell {

    weak var comment: Comment! {
        didSet {
            if Thread.isMainThread {
                self.refresh()
            } else {
                DispatchQueue.main.async {
                    self.refresh()
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

    private func refresh() {
        if let comment = comment {
            if let activityIndicatorView = activityIndicatorView, (comment.body == nil || comment.body.length == 0) {
                activityIndicatorView.startAnimating()
                bringSubview(toFront: activityIndicatorView)
            }

            if let imageAttachments = comment.attachments {
                if imageAttachments.count > 0 {
                    for attachment in imageAttachments {
                        attachmentPreviewImageView?.contentMode = .scaleAspectFit
                        if let attachmentURL = attachment.url {
                            attachmentPreviewImageView?.sd_setImage(with: attachmentURL, completed: { image, error, cacheType, url in
                                if let attachmentPreviewImageView = self.attachmentPreviewImageView {
                                    attachmentPreviewImageView.alpha = 1.0
                                    self.bringSubview(toFront: attachmentPreviewImageView)
                                }
                                self.activityIndicatorView?.stopAnimating()
                            })
                        } else {
                            comment.reload(onSuccess: { statusCode, mappingResult in
                                self.refresh()
                            }, onError: { error, statusCode, responseString in
                                logError(error)
                            })
                        }
                    }
                } else {
                    activityIndicatorView?.stopAnimating()
                }
            } else {
                self.activityIndicatorView?.stopAnimating()
                self.attachmentPreviewImageView.alpha = 0.0
            }

            bodyTextView?.isEditable = false

            nameLabel?.text = comment.user.name
            bodyTextView?.text = comment.body

            if let imageUrl = comment.user.profileImageUrl {
                imageView.contentMode = .scaleAspectFit
                imageView.sd_setImage(with: imageUrl as URL!, completed: { image, error, cacheType, url in
                    self.contentView.bringSubview(toFront: self.imageView)
                    self.imageView.makeCircular()

                    self.imageView.alpha = 1.0
                })
            } else {
                imageView.alpha = 0.0
                imageView.image = nil
            }

            let date = comment.createdAtDate!
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
        } else {
            prepareForReuse()
        }
    }
}
