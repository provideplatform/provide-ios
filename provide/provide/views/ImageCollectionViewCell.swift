//
//  ImageCollectionViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 7/23/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var imageView: UIImageView!

    var imageUrl: NSURL! {
        didSet {
            if let imageUrl = imageUrl {
                imageView.contentMode = .ScaleAspectFill
                imageView.sd_setImageWithURL(imageUrl) { image, error, cacheType, url in
                    self.imageView.alpha = 1.0
                    self.activityIndicatorView.stopAnimating()
                }
            } else {
                imageView.alpha = 0.0
                imageView.image = nil

                activityIndicatorView.startAnimating()
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageUrl = nil
    }
}
