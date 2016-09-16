//
//  CategoryTableViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 3/19/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

class CategoryTableViewCell: UITableViewCell {

    @IBOutlet fileprivate weak var iconImageView: UIImageView!
    @IBOutlet fileprivate weak var nameLabel: UILabel!
    @IBOutlet fileprivate weak var activityIndicatorView: UIActivityIndicatorView!

    fileprivate var pinView: FloorplanPinView!

    var category: Category! {
        didSet {
            if Thread.isMainThread {
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

    fileprivate func refresh() {
        if let category = category {
            nameLabel?.text = category.name

            activityIndicatorView?.startAnimating()

            iconImageView?.contentMode = .scaleAspectFit

            if let iconImageUrl = category.iconImageUrl {
                iconImageView?.sd_setImage(with: iconImageUrl, placeholderImage: nil, options: .retryFailed,
                                                  completed: { image, error, cacheType, url in
                                                    self.activityIndicatorView?.stopAnimating()
                                                    self.iconImageView?.alpha = 1.0
                    }
                )
            } else {
                pinView = FloorplanPinView(annotation: nil)
                pinView?.contentMode = .scaleAspectFit
                pinView?.category = category

                iconImageView?.image = pinView?.toImage()
                iconImageView?.alpha = 1.0
                activityIndicatorView?.stopAnimating()
            }
        }
    }
}
