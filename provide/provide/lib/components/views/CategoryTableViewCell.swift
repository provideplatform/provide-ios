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

    var category: Category! {
        didSet {
            if let category = category {
                nameLabel?.text = category.name

                activityIndicatorView?.startAnimating()
                
                iconImageView?.sd_setImageWithURL(category.iconImageUrl, placeholderImage: nil, options: .RetryFailed,
                    completed: { image, error, cacheType, url in
                        self.activityIndicatorView?.stopAnimating()
                        self.iconImageView?.alpha = 1.0
                    }
                )
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel?.text = ""
        
        iconImageView?.image = nil
        iconImageView?.alpha = 0.0

        activityIndicatorView?.startAnimating()
    }
}
