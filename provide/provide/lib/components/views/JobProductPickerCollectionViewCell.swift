//
//  JobProductPickerCollectionViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 1/5/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

class JobProductPickerCollectionViewCell: PickerCollectionViewCell {

    var jobProduct: JobProduct! {
        didSet {
            if let jobProduct = jobProduct {
                quantityLabel?.text = NSString(format: "%.03f", jobProduct.initialQuantity) as String
                quantityLabel?.sizeToFit()

                priceLabel?.text = NSString(format: "$%.02f", jobProduct.price) as String
                priceLabel?.sizeToFit()

                renderStatusBackgroundView()
            }
        }
    }

    override var imageUrl: URL! {
        didSet {
            if let imageUrl = imageUrl {
                self.showActivityIndicator()

                imageView.contentMode = .scaleAspectFit
                imageView.sd_setImage(with: imageUrl, completed: { image, error, cacheType, url in
                    self.contentView.bringSubview(toFront: self.imageView)
                    self.contentView.bringSubview(toFront: self.quantityLabel)
                    self.contentView.bringSubview(toFront: self.priceLabel)
                    if self.rendersCircularImage {
                        self.imageView.makeCircular()
                    }
                    self.imageView.alpha = 1.0

                    self.hideActivityIndicator()
                })
            } else {
                imageView.image = nil
                imageView.alpha = 0.0
            }
        }
    }

    @IBOutlet internal weak var quantityLabel: UILabel! {
        didSet {
            if let quantityLabel = quantityLabel {
                quantityLabel.text = ""
            }
        }
    }

    @IBOutlet internal weak var priceLabel: UILabel! {
        didSet {
            if let priceLabel = priceLabel {
                priceLabel.text = ""
            }
        }
    }

    @IBOutlet internal weak var statusBackgroundView: UIView! {
        didSet {
            if let _ = statusBackgroundView {
                resetStatusBackgroundView()
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        resetStatusBackgroundView()

        quantityLabel?.text = ""
        priceLabel?.text = ""
    }

    override func setAccessoryImage(_ image: UIImage, tintColor: UIColor) {
        super.setAccessoryImage(image, tintColor: tintColor)
    }

    fileprivate func resetStatusBackgroundView() {
        statusBackgroundView.roundCorners(5.0)
        statusBackgroundView.alpha = 0.8
        statusBackgroundView.backgroundColor = UIColor.clear
        statusBackgroundView.frame.size = CGSize(width: 0.0, height: statusBackgroundView.frame.height)

        contentView.sendSubview(toBack: statusBackgroundView)
    }

    fileprivate func renderStatusBackgroundView() {
        dispatch_after_delay(0.0) {
            self.resetStatusBackgroundView()
            self.statusBackgroundView.backgroundColor = self.jobProduct.statusColor

            UIView.animate(withDuration: 0.4, delay: 0.15, options: .curveEaseInOut,
                animations: {
                    self.statusBackgroundView.frame = CGRect(x: 0.0,
                                                             y: 0.0,
                                                             width: CGFloat(self.contentView.bounds.width) * CGFloat(self.jobProduct.percentageRemaining),
                                                             height: self.contentView.bounds.height)
                },
                completion: { complete in

                }
            )
        }
    }
}
