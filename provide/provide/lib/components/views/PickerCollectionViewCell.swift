//
//  PickerCollectionViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 11/18/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
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

    internal var firstName: String? {
        if let name = name {
            if name.components(separatedBy: " ").count > 1 {
                return name.components(separatedBy: " ").first!
            } else {
                return name
            }
        } else {
            return nil
        }
    }

    internal var lastName: String? {
        if let name = name {
            if name.components(separatedBy: " ").count > 1 {
                return name.components(separatedBy: " ").last!
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    var imageUrl: URL! {
        didSet {
            if let imageUrl = imageUrl {
                self.showActivityIndicator()

                initialsLabel?.text = ""
                initialsLabel?.alpha = 0.0

                if let imageView = imageView {
                    imageView.contentMode = .scaleAspectFit
                    imageView.sd_setImage(with: imageUrl, completed: { image, error, cacheType, url in
                        self.gravatarImageView?.alpha = 0.0

                        self.contentView.bringSubview(toFront: self.imageView)
                        if self.rendersCircularImage {
                            self.imageView.makeCircular()
                        }
                        self.imageView.alpha = 1.0

                        self.hideActivityIndicator()
                    })
                }
            } else {
                imageView?.image = nil
                imageView?.alpha = 0.0
            }
        }
    }

    var gravatarEmail: String! {
        didSet {
            if let _ = gravatarEmail {
                showActivityIndicator()

                imageView.image = nil
                imageView.alpha = 0.0

                renderInitials()

//                gravatarImageView.defaultGravatar = .GravatarBlank
//                gravatarImageView.email = gravatarEmail
//                gravatarImageView.size = UInt(gravatarImageView.frame.width)
//                gravatarImageView.load { error in
//                    if self.rendersCircularImage {
//                        self.gravatarImageView.makeCircular()
//                    }
//                    self.contentView.bringSubviewToFront(self.gravatarImageView)
//                    self.gravatarImageView.alpha = 1.0
//                    self.hideActivityIndicator()
//                }
            }
        }
    }

    internal var initials: String! {
        if let _ = name {
            var initials = ""
            if let firstName = firstName {
                initials = "\(firstName.substring(to: firstName.characters.index(firstName.startIndex, offsetBy: 1)))"
            }
            if let lastName = lastName {
                initials = "\(initials)\(lastName.substring(from: lastName.startIndex).substring(to: lastName.characters.index(lastName.startIndex, offsetBy: 1)))"
            }
            return initials
        }
        return nil
    }

    var accessoryImage: UIImage! {
        didSet {
            if let accessoryImage = accessoryImage {
                accessoryImageView?.image = accessoryImage
                accessoryImageView?.alpha = 1.0
                if let accessoryImageView = accessoryImageView {
                    contentView.bringSubview(toFront: accessoryImageView)
                }
            } else {
                accessoryImageView?.alpha = 0.0
                accessoryImageView?.image = nil
            }
        }
    }

    var selectedImage: UIImage! {
        didSet {
            if let selectedImage = selectedImage {
                selectedImageView.alpha = isSelected ? 1.0 : 0.0
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

    override var isSelected: Bool {
        didSet {
            if isSelected {
                selectedImageView?.alpha = 1.0
            } else {
                selectedImageView?.alpha = 0.0
            }
        }
    }

    @IBOutlet internal weak var activityIndicatorView: UIActivityIndicatorView! {
        didSet {
            if let activityIndicatorView = activityIndicatorView {
                bringSubview(toFront: activityIndicatorView)
            }
        }
    }

    @IBOutlet internal weak var nameLabel: UILabel! {
        didSet {
            if let nameLabel = nameLabel {
                defaultFont = nameLabel.font
            }
        }
    }

    @IBOutlet internal weak var initialsLabel: UILabel! {
        didSet {
            if  let initialsLabel = initialsLabel {
                initialsLabel.makeCircular()
            }
        }
    }

    @IBOutlet internal weak var imageView: UIImageView! {
        didSet {
            if let imageView = imageView {
                defaultImageViewFrame = imageView.frame
                contentView.sendSubview(toBack: imageView)

                gravatarImageView = UIImageView(frame: defaultImageViewFrame)
            }
        }
    }

    @IBOutlet internal weak var accessoryImageView: UIImageView! {
        didSet {
            if let accessoryImageView = accessoryImageView {
                accessoryImageView.contentMode = .scaleAspectFit
                accessoryImageView.image = nil
                accessoryImageView.alpha = 0.0

                contentView.bringSubview(toFront: accessoryImageView)
            }
        }
    }

    @IBOutlet internal weak var selectedImageView: UIImageView! {
        didSet {
            if let selectedImageView = selectedImageView {
                selectedImageView.contentMode = .scaleAspectFit
                selectedImageView.image = UIImage(named: "map-pin")?.scaledToWidth(25.0)
                selectedImageView.alpha = 0.0

                contentView.bringSubview(toFront: selectedImageView)
                contentView.bringSubview(toFront: nameLabel)
            }
        }
    }

    internal var gravatarImageView: UIImageView! {
        didSet {
            if let gravatarImageView = gravatarImageView {
                contentView.addSubview(gravatarImageView)
                contentView.sendSubview(toBack: gravatarImageView)
            }
        }
    }

    internal var defaultFont: UIFont!
    internal var defaultImageViewFrame: CGRect!

    internal var highlightedFont: UIFont! {
        if let defaultFont = defaultFont {
            let name = defaultFont.fontName.components(separatedBy: "-").first!
            return UIFont(name: "\(name)-Bold", size: defaultFont.pointSize)
        }
        return nil
    }

    internal var highlightedImageViewFrame: CGRect! {
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

        nameLabel?.text = ""

        imageView?.image = nil
        imageView?.alpha = 0.0

        accessoryImageView?.alpha = 0.0
        selectedImageView?.alpha = 0.0

        gravatarEmail = nil
        gravatarImageView?.image = nil
        gravatarImageView?.alpha = 0.0

        initialsLabel?.text = ""
        initialsLabel?.alpha = 0.0

        showActivityIndicator()

        isSelected = false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        highlighted()
    }

    override func touchesCancelled(_ touches: Set<UITouch>?, with event: UIEvent?) {
        super.touchesCancelled(touches!, with: event)

        unhighlighted()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        unhighlighted()
    }

    func setAccessoryImage(_ image: UIImage, tintColor: UIColor) {
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
            initialsLabel?.textColor = UIColor.white
            initialsLabel?.backgroundColor = Color.annotationViewBackgroundImageColor().withAlphaComponent(0.8)
            initialsLabel?.alpha = 1.0

            if let initialsLabel = initialsLabel {
                contentView.bringSubview(toFront: initialsLabel)
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

    fileprivate func unhighlighted() {
        nameLabel?.font = defaultFont

        imageView?.frame = defaultImageViewFrame

        gravatarImageView?.frame = defaultImageViewFrame
    }

    fileprivate func highlighted() {
        nameLabel?.font = highlightedFont

        imageView?.frame = highlightedImageViewFrame

        gravatarImageView?.frame = highlightedImageViewFrame
    }
}
