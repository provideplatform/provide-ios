//
//  PickerCollectionViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 11/18/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class PickerCollectionViewCell: UICollectionViewCell {

    var name: String! {
        didSet {
            if let name = name {
                nameLabel.text = name
            } else {
                nameLabel.text = ""
            }
        }
    }

    var imageUrl: NSURL! {
        didSet {
            if let imageUrl = imageUrl {
                imageView.contentMode = .ScaleAspectFit
                imageView.sd_setImageWithURL(imageUrl, completed: { image, error, cacheType, url in
                    self.gravatarImageView?.alpha = 0.0

                    self.contentView.bringSubviewToFront(self.imageView)
                    self.imageView.makeCircular()
                    self.imageView.alpha = 1.0
                })
            } else {
                imageView.image = nil
                imageView.alpha = 0.0
            }
        }
    }

    var gravatarEmail: String! {
        didSet {
            if let gravatarEmail = gravatarEmail {
                imageView.image = nil
                imageView.alpha = 0.0

                gravatarImageView.email = gravatarEmail
                gravatarImageView.size = UInt(gravatarImageView.frame.width)
                gravatarImageView.load { error in
                    self.gravatarImageView.makeCircular()
                    self.gravatarImageView.alpha = 1.0
                }
            }
        }
    }

    var accessoryImage: UIImage! {
        didSet {
            if let accessoryImage = accessoryImage {
                accessoryImageView.image = accessoryImage
                accessoryImageView.alpha = 1.0
            } else {
                accessoryImageView.alpha = 0.0
                accessoryImageView.image = nil
            }
        }
    }

    var selectedImage: UIImage! {
        didSet {
            if let selectedImage = selectedImage {
                selectedImageView.alpha = selected ? 1.0 : 0.0
                selectedImageView.image = selectedImage
            }
        }
    }

    override var selected: Bool {
        didSet {
            if selected {
                selectedImageView.alpha = 1.0
            } else {
                selectedImageView.alpha = 0.0
            }
        }
    }

    @IBOutlet private weak var nameLabel: UILabel! {
        didSet {
            if let nameLabel = nameLabel {
                defaultFont = nameLabel.font
            }
        }
    }

    @IBOutlet private weak var imageView: UIImageView! {
        didSet {
            if let imageView = imageView {
                defaultImageViewFrame = imageView.frame
                contentView.sendSubviewToBack(imageView)

                gravatarImageView = RFGravatarImageView(frame: defaultImageViewFrame)
            }
        }
    }

    @IBOutlet private weak var accessoryImageView: UIImageView! {
        didSet {
            if let accessoryImageView = accessoryImageView {
                accessoryImageView.contentMode = .ScaleAspectFit
                accessoryImageView.image = nil
                accessoryImageView.alpha = 0.0

                contentView.bringSubviewToFront(accessoryImageView)
            }
        }
    }

    @IBOutlet private weak var selectedImageView: UIImageView! {
        didSet {
            if let selectedImageView = selectedImageView {
                selectedImageView.contentMode = .ScaleAspectFit
                selectedImageView.image = UIImage(named: "map-pin")?.scaledToWidth(25.0)
                selectedImageView.alpha = 0.0

                contentView.bringSubviewToFront(selectedImageView)
                contentView.bringSubviewToFront(nameLabel)
            }
        }
    }

    private var gravatarImageView: RFGravatarImageView! {
        didSet {
            if let gravatarImageView = gravatarImageView {
                contentView.addSubview(gravatarImageView)
                contentView.sendSubviewToBack(gravatarImageView)
            }
        }
    }

    private var defaultFont: UIFont!
    private var defaultImageViewFrame: CGRect!

    private var highlightedFont: UIFont! {
        if let defaultFont = defaultFont {
            let name = defaultFont.fontName.splitAtString("-").0
            return UIFont(name: "\(name)-Bold", size: defaultFont.pointSize)
        }
        return nil
    }

    private var highlightedImageViewFrame: CGRect! {
        if let defaultImageViewFrame = defaultImageViewFrame {
            let offsetFrame = defaultImageViewFrame.offsetBy(dx: -2.5, dy: -2.5)
            return CGRect(x: offsetFrame.origin.x,
                          y: offsetFrame.origin.y,
                          width: offsetFrame.size.width + 5.0,
                          height: offsetFrame.size.height + 5.0)
        }
        return nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        nameLabel.text = ""

        imageView.image = nil
        imageView.alpha = 0.0

        accessoryImageView.alpha = 0.0
        selectedImageView.alpha = 0.0

        gravatarEmail = nil
        gravatarImageView?.image = nil
        gravatarImageView?.alpha = 0.0

        selected = false
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)

        highlighted()
    }

    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)

        unhighlighted()
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)

        unhighlighted()
    }

    private func unhighlighted() {
        nameLabel.font = defaultFont

        imageView.frame = defaultImageViewFrame

        gravatarImageView?.frame = defaultImageViewFrame
    }

    private func highlighted() {
        nameLabel.font = highlightedFont

        imageView.frame = highlightedImageViewFrame

        gravatarImageView?.frame = highlightedImageViewFrame
    }
}
