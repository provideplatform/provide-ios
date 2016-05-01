//
//  JobTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 11/17/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol JobTableViewCellDelegate {
    func jobTableViewCell(tableViewCell: JobTableViewCell, shouldCancelJob job: Job)
}

class JobTableViewCell: SWTableViewCell, SWTableViewCellDelegate {

    var jobTableViewCellDelegate: JobTableViewCellDelegate!

    var job: Job! {
        didSet {
            if let _ = job {
                refresh()
            }
        }
    }

    @IBOutlet weak var containerView: UIView!
    @IBOutlet private weak var backgroundContainerView: UIView!

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var thumbnailImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!

    private var showsCancelButton: Bool {
        if job == nil {
            return false
        }
        return job.status != "completed" && job.status != "canceled"
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        backgroundColor = UIColor.clearColor()
        contentView.backgroundColor = UIColor.clearColor()

        delegate = self

        refreshUtilityButtons()

        NSNotificationCenter.defaultCenter().addObserverForName("AttachmentChanged") { notification in
            if let attachment = notification.object as? Attachment {
                if let attachableType = attachment.attachableType {
                    if attachableType == "job" && attachment.attachableId == self.job.id {
                        if let mimeType = attachment.mimeType {
                            if mimeType == "image/png" {
                                let isAppropriateResolution = attachment.hasTag("72dpi")
                                let hasThumbnailTag = attachment.hasTag("thumbnail")
                                let isPublished = attachment.status == "published"
                                if isAppropriateResolution && hasThumbnailTag && isPublished {
                                    self.setThumbnailImageWithURL(attachment.url)
                                } else if let thumbnailUrl = attachment.thumbnailUrl {
                                    self.setThumbnailImageWithURL(thumbnailUrl)
                                }
                            }
                        }
                    }
                }
            }
        }

        NSNotificationCenter.defaultCenter().addObserverForName("JobChanged") { notification in
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

        activityIndicatorView?.startAnimating()

        thumbnailImageView?.alpha = 0.0
        thumbnailImageView?.image = nil
    }

    func dismiss() {
        UIView.animateWithDuration(0.3, delay: 0.1, options: .CurveEaseOut,
            animations: { [weak self] in
                if let superview = self?.rightUtilityButtons.first!.superview {
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

            setThumbnailImageWithURL(job.blueprintThumbnailImageUrl)
        }
    }

    func setThumbnailImageWithURL(url: NSURL!) {
        if let url = url {
            thumbnailImageView?.contentMode = .ScaleAspectFit
            thumbnailImageView?.sd_setImageWithURL(url, placeholderImage: nil, completed: { (image, error, cacheType, url) in
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
        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut,
            animations: {
                self.frame.origin.x = 0.0
                self.containerView.frame.origin.x = 0.0
                if let superview = self.rightUtilityButtons.first!.superview {
                    superview!.alpha = 1.0
                }
                self.hideUtilityButtonsAnimated(true)
            },
            completion: { complete in
                if self.selected && self.highlighted {
                    self.containerView.backgroundColor = UIColor.whiteColor()
                }
            }
        )

    }

    private func refreshUtilityButtons() {
        let leftUtilityButtons = NSMutableArray()
        let rightUtilityButtons = NSMutableArray()

        if showsCancelButton {
            rightUtilityButtons.sw_addUtilityButtonWithColor(Color.abandonedStatusColor(), title: "Cancel")
        }

        setLeftUtilityButtons(leftUtilityButtons as [AnyObject], withButtonWidth: 0.0)
        setRightUtilityButtons(rightUtilityButtons as [AnyObject], withButtonWidth: 120.0)
    }

    // MARK: SWTableViewCellDelegate

    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerLeftUtilityButtonWithIndex index: Int) {
        //  no-op
    }

    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex index: Int) {
        if index == 0 {
            if showsCancelButton {
                jobTableViewCellDelegate?.jobTableViewCell(self, shouldCancelJob: job)
            }
        }
    }

    func swipeableTableViewCell(cell: SWTableViewCell!, canSwipeToState state: SWCellState) -> Bool {
        return true
    }

    func swipeableTableViewCellShouldHideUtilityButtonsOnSwipe(cell: SWTableViewCell!) -> Bool {
        return true
    }

    func swipeableTableViewCell(cell: SWTableViewCell!, scrollingToState state: SWCellState) {
        // no-op
    }

    func swipeableTableViewCellDidEndScrolling(cell: SWTableViewCell!) {
        // no-op
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
