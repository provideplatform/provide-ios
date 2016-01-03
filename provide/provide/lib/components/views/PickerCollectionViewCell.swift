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

    private var firstName: String? {
        if let name = name {
            return name.splitAtString(" ", assertedComponentsCount: nil).0
        } else {
            return nil
        }
    }

    private var lastName: String? {
        if let name = name {
            return name.splitAtString(" ", assertedComponentsCount: nil).1
        } else {
            return nil
        }
    }

    var imageUrl: NSURL! {
        didSet {
            if let imageUrl = imageUrl {
                self.showActivityIndicator()

                initialsLabel?.text = ""
                initialsLabel?.alpha = 0.0

                imageView.contentMode = .ScaleAspectFit
                imageView.sd_setImageWithURL(imageUrl, completed: { image, error, cacheType, url in
                    self.gravatarImageView?.alpha = 0.0

                    self.contentView.bringSubviewToFront(self.imageView)
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

    var gravatarEmail: String! {
        didSet {
            if let gravatarEmail = gravatarEmail {
                showActivityIndicator()

                imageView.image = nil
                imageView.alpha = 0.0

                renderInitials()

                gravatarImageView.defaultGravatar = .GravatarBlank
                gravatarImageView.email = gravatarEmail
                gravatarImageView.size = UInt(gravatarImageView.frame.width)
                gravatarImageView.load { error in
                    if self.rendersCircularImage {
                        self.gravatarImageView.makeCircular()
                    }
                    self.contentView.bringSubviewToFront(self.gravatarImageView)
                    self.gravatarImageView.alpha = 1.0
                    self.hideActivityIndicator()
                }
            }
        }
    }

    private var initials: String! {
        if let _ = name {
            var initials = ""
            if let firstName = firstName {
                initials = "\(firstName.substringToIndex(firstName.startIndex.advancedBy(1)))"
            }
            if let lastName = lastName {
                initials = "\(initials)\(lastName.substringFromIndex(lastName.startIndex).substringToIndex(lastName.startIndex.advancedBy(1)))"
            }
            return initials
        }
        return nil
    }

    var accessoryImage: UIImage! {
        didSet {
            if let accessoryImage = accessoryImage {
                accessoryImageView.image = accessoryImage
                accessoryImageView.alpha = 1.0
                contentView.bringSubviewToFront(accessoryImageView)
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

    var rendersCircularImage = true {
        didSet {
            if let imageView = imageView {
                if oldValue && !rendersCircularImage {
                    imageView.layer.cornerRadius = frame.width * 2
                    imageView.layer.masksToBounds = false
                } else if !oldValue && rendersCircularImage {
                    imageView.layer.cornerRadius = frame.width / 2
                    imageView.layer.masksToBounds = true
                }
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

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView! {
        didSet {
            if let activityIndicatorView = activityIndicatorView {
                bringSubviewToFront(activityIndicatorView)
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

    @IBOutlet private weak var initialsLabel: UILabel! {
        didSet {
            if  let initialsLabel = initialsLabel {
                initialsLabel.makeCircular()
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

        initialsLabel?.text = ""
        initialsLabel?.alpha = 0.0

        showActivityIndicator()

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

    func setAccessoryImage(image: UIImage, tintColor: UIColor) {
        accessoryImageView?.tintColor = tintColor
        accessoryImage = image
    }

    func hideActivityIndicator() {
        imageView?.alpha = 1.0
        gravatarImageView?.alpha = 1.0
        initialsLabel?.alpha = 1.0
        activityIndicatorView?.stopAnimating()
    }

    func renderInitials() {
        if let initials = initials {
            initialsLabel?.text = initials
            initialsLabel?.textColor = UIColor.whiteColor()
            initialsLabel?.backgroundColor = Color.annotationViewBackgroundImageColor().colorWithAlphaComponent(0.8)
            initialsLabel?.alpha = 1.0

            if let initialsLabel = initialsLabel {
                contentView.bringSubviewToFront(initialsLabel)
            }

            hideActivityIndicator()
        }
    }

    func showActivityIndicator() {
        imageView?.alpha = 0.0
        initialsLabel?.alpha = 0.0
        gravatarImageView?.alpha = 0.0
        activityIndicatorView?.startAnimating()
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
