//
//  JobProductPickerCollectionViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 1/5/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

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

    override var imageUrl: NSURL! {
        didSet {
            if let imageUrl = imageUrl {
                self.showActivityIndicator()

                imageView.contentMode = .ScaleAspectFit
                imageView.sd_setImageWithURL(imageUrl, completed: { image, error, cacheType, url in
                    self.contentView.bringSubviewToFront(self.imageView)
                    self.contentView.bringSubviewToFront(self.quantityLabel)
                    self.contentView.bringSubviewToFront(self.priceLabel)
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

    @IBOutlet private weak var quantityLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!

    @IBOutlet private weak var statusBackgroundView: UIView! {
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

    override func setAccessoryImage(image: UIImage, tintColor: UIColor) {
        super.setAccessoryImage(image, tintColor: tintColor)

//        statusBackgroundView.frame = CGRect(x: 0.0,
//            y: 0.0,
//            width: contentView.bounds.width * jobProduct.percentageRemaining,
//            height: contentView.bounds.height)

    }

    private func resetStatusBackgroundView() {
        statusBackgroundView.roundCorners(5.0)
        statusBackgroundView.alpha = 0.8
        statusBackgroundView.backgroundColor = UIColor.clearColor()
        statusBackgroundView.frame.size = CGSize(width: 0.0, height: statusBackgroundView.frame.height)

        contentView.sendSubviewToBack(statusBackgroundView)
    }

    private func renderStatusBackgroundView() {
        //resetStatusBackgroundView()

        dispatch_after_delay(0.0) {
            self.statusBackgroundView.backgroundColor = self.jobProduct.statusColor

            UIView.animateWithDuration(0.4, delay: 0.15, options: .CurveEaseInOut,
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
