//
//  JobTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 11/17/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import SWTableViewCell
import KTSwiftExtensions

protocol JobTableViewCellDelegate {
    func jobTableViewCell(_ tableViewCell: JobTableViewCell, shouldCancelJob job: Job)
}

class JobTableViewCell: SWTableViewCell, SWTableViewCellDelegate {

    var jobTableViewCellDelegate: JobTableViewCellDelegate!

    var job: Job! {
        didSet {
            if let _ = job {
                if Thread.isMainThread {
                    self.refresh()
                } else {
                    dispatch_after_delay(0.0) {
                        self.refresh()
                    }
                }
            }
        }
    }

    @IBOutlet weak var containerView: UIView!
    @IBOutlet fileprivate weak var backgroundContainerView: UIView!

    @IBOutlet fileprivate weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet fileprivate weak var thumbnailImageView: UIImageView!
    @IBOutlet fileprivate weak var nameLabel: UILabel!
    @IBOutlet fileprivate weak var customerNameLabel: UILabel!

    fileprivate var showsCancelButton: Bool {
        if job == nil {
            return false
        }
        var isSupervisor = job.isCurrentUserCompanyAdmin
        if !isSupervisor {
            if let providers = currentUser().providers {
                for provider in providers {
                    if job.hasSupervisor(provider) {
                        isSupervisor = true
                        break
                    }
                }
            }
        }

        return isSupervisor && job.status != "completed" && job.status != "canceled"
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear

        delegate = self

        refreshUtilityButtons()

        NotificationCenter.default.addObserverForName("AttachmentChanged") { notification in
            if let attachment = notification.object as? Attachment {
                if let attachableType = attachment.attachableType {
                    if attachableType == "job" && attachment.attachableId == self.job.id {
                        if let mimeType = attachment.mimeType {
                            if mimeType == "image/png" {
                                let isAppropriateResolution = attachment.hasTag("72dpi")
                                let hasThumbnailTag = attachment.hasTag("thumbnail")
                                let isPublished = attachment.status == "published"
                                if isAppropriateResolution && hasThumbnailTag && isPublished {
                                    self.setThumbnailImageWithURL(attachment.url as URL!)
                                } else if let thumbnailUrl = attachment.thumbnailUrl {
                                    self.setThumbnailImageWithURL(thumbnailUrl as URL!)
                                }
                            }
                        }
                    }
                }
            }
        }

        NotificationCenter.default.addObserverForName("JobChanged") { notification in
            if let job = notification.object as? Job {
                if let j = self.job {
                    if job.id == j.id {
                        self.job = job
                    }
                }
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel?.text = ""
        customerNameLabel?.text = ""

        activityIndicatorView?.startAnimating()

        thumbnailImageView?.alpha = 0.0
        thumbnailImageView?.image = nil
    }

    func dismiss() {
        UIView.animate(withDuration: 0.3, delay: 0.1, options: .curveEaseOut,
            animations: { [weak self] in
                if let superview = (self?.rightUtilityButtons.first! as AnyObject).superview {
                    superview!.backgroundColor = Color.abandonedStatusColor()
                    superview!.alpha = 1.0
                }
                self!.frame.origin.x = self!.frame.size.width * -2.0
            },
            completion: { complete in

            }
        )
    }

    func refresh() {
        refreshUtilityButtons()

        if let job = job {
            nameLabel?.text = job.name
            nameLabel?.sizeToFit()

            customerNameLabel?.text = job.customer.displayName
            customerNameLabel?.sizeToFit()

            setThumbnailImageWithURL(job.thumbnailImageUrl as URL!)
        }
    }

    func setThumbnailImageWithURL(_ url: URL!) {
        if let url = url {
            thumbnailImageView?.contentMode = .scaleAspectFit
            thumbnailImageView?.sd_setImage(with: url, completed: { (image, error, cacheType, url) in
                if let image = self.thumbnailImageView?.image {
                    self.thumbnailImageView?.bounds.size = image.size
                    self.thumbnailImageView?.frame.size = image.size

                    self.thumbnailImageView?.alpha = 1.0

                    self.activityIndicatorView?.stopAnimating()
                }
            })
        }
    }

    func reset() {
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut,
            animations: {
                self.frame.origin.x = 0.0
                self.containerView.frame.origin.x = 0.0
                if let superview = (self.rightUtilityButtons.first! as AnyObject).superview {
                    superview!.alpha = 1.0
                }
                self.hideUtilityButtons(animated: true)
            },
            completion: { complete in
                if self.isSelected && self.isHighlighted {
                    self.containerView.backgroundColor = UIColor.white
                }
            }
        )

    }

    fileprivate func refreshUtilityButtons() {
        let leftUtilityButtons = NSMutableArray()
        let rightUtilityButtons = NSMutableArray()

        if showsCancelButton {
            rightUtilityButtons.sw_addUtilityButton(with: Color.abandonedStatusColor(), title: "Cancel")
        }

        setLeftUtilityButtons(leftUtilityButtons as [AnyObject], withButtonWidth: 0.0)
        setRightUtilityButtons(rightUtilityButtons as [AnyObject], withButtonWidth: 120.0)
    }

    // MARK: SWTableViewCellDelegate

    func swipeableTableViewCell(_ cell: SWTableViewCell!, didTriggerLeftUtilityButtonWith index: Int) {
        //  no-op
    }

    func swipeableTableViewCell(_ cell: SWTableViewCell!, didTriggerRightUtilityButtonWith index: Int) {
        if index == 0 {
            if showsCancelButton {
                jobTableViewCellDelegate?.jobTableViewCell(self, shouldCancelJob: job)
            }
        }
    }

    func swipeableTableViewCell(_ cell: SWTableViewCell!, canSwipeTo state: SWCellState) -> Bool {
        return true
    }

    func swipeableTableViewCellShouldHideUtilityButtons(onSwipe cell: SWTableViewCell!) -> Bool {
        return true
    }

    func swipeableTableViewCell(_ cell: SWTableViewCell!, scrollingTo state: SWCellState) {
        // no-op
    }

    func swipeableTableViewCellDidEndScrolling(_ cell: SWTableViewCell!) {
        // no-op
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
