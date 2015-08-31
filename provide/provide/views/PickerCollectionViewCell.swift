//
//  PickerCollectionViewCell.swift
//  provide
//
//  Created by Kyle Thomas on 1/5/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class PickerCollectionViewCell: UICollectionViewCell {

    var gravatarEmail: String! {
        didSet {
            imageView.alpha = 0

            if imageView is RFGravatarImageView {
                (imageView as! RFGravatarImageView).email = gravatarEmail
                (imageView as! RFGravatarImageView).load { (error) -> Void in
                    self.imageView.makeCircular()
                    self.imageView.alpha = 1
                }
            }
        }
    }

    var image: UIImage! {
        didSet {
            if let image = self.image {
                imageView.image = image
                imageView.makeCircular()
                imageView.alpha = 1
            } else {
                imageView.alpha = 0
            }
        }
    }

    var name: String! {
        didSet {
            nameLabel.text = name
        }
    }

    var selectedBackgroundColor = Color.darkBlueBackground()
    var selectableViews = [UIView]()
    var unselectedBackgroundColor = Color.darkBlueBackground()

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        alpha = 0

        selectableViews = [self]
    }

    func attachGestureRecognizers() {
        removeGestureRecognizers()

        let recognizer = GestureRecognizer(collectionViewCell: self)
        addGestureRecognizer(recognizer)
    }

    override func removeGestureRecognizers() {
        if let gestureRecognizers = self.gestureRecognizers {
            for recognizer in gestureRecognizers {
                removeGestureRecognizer(recognizer)
            }
        }
    }

    private class GestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {

        private weak var collectionViewCell: PickerCollectionViewCell!

        private var initialProfileImageFrame: CGRect!

        var selected: Bool = false {
            didSet {
                var color = collectionViewCell.unselectedBackgroundColor
                if selected == true {
                    color = collectionViewCell.selectedBackgroundColor

                    collectionViewCell.imageView.frame = CGRectMake(initialProfileImageFrame.origin.x - 5,
                                                                    initialProfileImageFrame.origin.y - 5,
                                                                    initialProfileImageFrame.size.width + 5,
                                                                    initialProfileImageFrame.size.height + 5)
                } else {
                    collectionViewCell.imageView.frame = initialProfileImageFrame
                }

                for view in collectionViewCell.selectableViews {
                    view.backgroundColor = color
                }
            }
        }

        required init(collectionViewCell: PickerCollectionViewCell) {
            super.init(target: collectionViewCell, action: "check")
            self.collectionViewCell = collectionViewCell
            self.initialProfileImageFrame = collectionViewCell.imageView.frame
            delegate = self
        }

        func check() {

        }

        override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
            selected = true
        }

        override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
            selected = false
        }

        override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
            if selected == true {

            }

            selected = false
        }

        // MARK: UIGestureRecognizerDelegate

        @objc func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }

        @objc func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
            return true
        }
    }
}
