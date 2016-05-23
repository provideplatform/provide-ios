//
//  CategoryTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 3/19/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class CategoryTableViewCell: UITableViewCell {

    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    private var pinView: FloorplanPinView!

    var category: Category! {
        didSet {
            if NSThread.isMainThread() {
                self.refresh()
            } else {
                dispatch_after_delay(0.0) {
                    self.refresh()
                }
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel?.text = ""
        
        iconImageView?.image = nil
        iconImageView?.alpha = 0.0

        activityIndicatorView?.startAnimating()

        pinView?.removeFromSuperview()
        pinView = nil
    }

    private func refresh() {
        if let category = category {
            nameLabel?.text = category.name

            activityIndicatorView?.startAnimating()

            iconImageView?.contentMode = .ScaleAspectFit

            if let iconImageUrl = category.iconImageUrl {
                iconImageView?.sd_setImageWithURL(iconImageUrl, placeholderImage: nil, options: .RetryFailed,
                                                  completed: { image, error, cacheType, url in
                                                    self.activityIndicatorView?.stopAnimating()
                                                    self.iconImageView?.alpha = 1.0
                    }
                )
            } else {
                pinView = FloorplanPinView(annotation: nil)
                pinView?.contentMode = .ScaleAspectFit
                pinView?.category = category

                iconImageView?.image = pinView?.toImage()
                iconImageView?.alpha = 1.0
                activityIndicatorView?.stopAnimating()
            }
        }
    }
}
