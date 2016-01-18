//
//  FloorplanCollectionViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 1/18/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class FloorplanCollectionViewCell: UICollectionViewCell {

    var floorplan: Floorplan! {
        didSet {
            imageView.contentMode = .ScaleAspectFit
            if let imageUrl = floorplan.profileImageUrl {
                imageView.sd_setImageWithURL(imageUrl, placeholderImage: nil) { image, error, cacheType, url in
                    self.imageView.alpha = 1.0
                    self.activityIndicatorView.stopAnimating()
                }
            }

            nameLabel.text = floorplan.name
        }
    }

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!

    override func prepareForReuse() {
        super.prepareForReuse()

        imageView.alpha = 0.0
        imageView.image = nil

        nameLabel.text = ""

        activityIndicatorView.startAnimating()
    }
}
