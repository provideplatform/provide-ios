//
//  MessagesTitleView.swift
//  provide
//
//  Created by Kyle Thomas on 2/14/17.
//  Copyright © 2017 Provide Technologies Inc.. All rights reserved.
//

import Foundation

class MessagesTitleView: UIView {

    @IBOutlet private weak var profileImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        profileImageView.tintColor = .white
        nameLabel.text = ""
        nameLabel.isHidden = true
        titleLabel.shadowOffset = CGSize(width: 0.0, height: -1.0)
        titleLabel.isHidden = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let superview = superview {
            frame.origin.x = superview.center.x - (frame.width / 2.0)
        }
    }

    func configure(name: String, profileImageUrl: URL?, height: CGFloat) {
        titleLabel.isHidden = true

        if let profileImageUrl = profileImageUrl {
            profileImageView.contentMode = .scaleAspectFit
            profileImageView.sd_setImage(with: profileImageUrl) { [weak self] image, error, imageCacheType, url in
                //self?.profileImageActivityIndicatorView.stopAnimating()

                self?.bringSubview(toFront: self!.profileImageView)
                self?.profileImageView.makeCircular()
                self?.profileImageView.alpha = 1.0
            }
        } else {
            profileImageView.image = nil
            profileImageView.alpha = 0.0
        }

        nameLabel.text = name
        nameLabel.isHidden = false

        frame.size.width = nameLabel.frame.width
        frame.size.height = height

        nameLabel.sizeToFit()

        let cornerLength: CGFloat = 4/30 * profileImageView.frame.width // 4 points on an image that has a width of 30 and proportional for others
        addHexagonalOutline(to: profileImageView, borderWidth: 2, cornerLength: cornerLength)
    }
}
