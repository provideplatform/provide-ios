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
            imageView.contentMode = .scaleAspectFit
            if let imageUrl = floorplan.thumbnailImageUrl {
                imageView.sd_setImage(with: imageUrl) { image, error, cacheType, url in
                    self.imageView.alpha = 1.0
                    self.activityIndicatorView.stopAnimating()
                }
            } else {
                imageView.image = nil
            }

            nameLabel.text = floorplan.name
        }
    }

    @IBOutlet fileprivate weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet fileprivate weak var imageView: UIImageView!
    @IBOutlet fileprivate weak var nameLabel: UILabel!

    override func prepareForReuse() {
        super.prepareForReuse()

        imageView.alpha = 0.0
        imageView.image = nil

        nameLabel.text = ""

        activityIndicatorView.startAnimating()
    }
}
