//
//  ImageCollectionViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 7/23/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {

    @IBOutlet fileprivate weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet fileprivate weak var imageView: UIImageView!

    var imageUrl: URL! {
        didSet {
            if let imageUrl = imageUrl {
                imageView.contentMode = .scaleAspectFill
                imageView.sd_setImage(with: imageUrl) { image, error, cacheType, url in
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
