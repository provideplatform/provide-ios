//
//  MessageCell.swift
//  provide
//
//  Created by Kyle Thomas on 2/6/17.
//  Copyright © 2017 Provide Technologies Inc.. All rights reserved.
//

import JSQMessagesViewController

class MessageCell: JSQMessagesCollectionViewCell {

    @IBOutlet private weak var mediaImageView: UIImageView!

    private weak var collectionViewController: JSQMessagesViewController!

    class func heightForMessageBubble(message: String, width: CGFloat) -> CGFloat {
        let tmpView = UITextView()
        tmpView.font = UIFont(name: "HelveticaNeue", size: 16.0)!
        tmpView.frame.size.width = width
        tmpView.text = message
        tmpView.sizeToFit()
        return tmpView.contentSize.height
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageView.tintColor = .white
        textView?.isScrollEnabled = false
        textView?.alpha = 0.0
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        avatarImageView.image = nil
        avatarImageView.sd_cancelCurrentImageLoad()
        textView?.alpha = 0.0
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let textView = textView {
            addHexagonalOutline(to: textView, borderWidth: 2, cornerLength: 5)
        }
    }

    dynamic private func mediaContainerViewTapped(gestureRecognizer: UIGestureRecognizer) {
        if let view = gestureRecognizer.view {
            presentMediaViewController(containerView: view)
        }
    }

    dynamic private func mediaViewControllerDismissed(gestureRecognizer: UIGestureRecognizer) {
        collectionViewController?.dismiss(animated: false)
    }

    private func presentMediaViewController(containerView: UIView?) {
        //        let aspectWidth = collectionView Controller.navigationController!.view.frame.width
        //        let aspectRatio = aspectWidth / collectionViewController.navigationController!.view.frame.height

        let mediaViewController = UIViewController()
        if let imageView = containerView?.subviews.first as? UIImageView, let image = imageView.image {
            let mediaImageView = UIImageView()
            mediaImageView.frame = CGRect(x: 0.0,
                                          y: 0.0,
                                          width: collectionViewController.collectionView.frame.width,
                                          height: collectionViewController.collectionView.frame.height)
            mediaImageView.center = collectionViewController.collectionView.center
            mediaImageView.contentMode = .scaleAspectFit
            mediaImageView.image = image
            mediaViewController.view.addSubview(mediaImageView)
            mediaViewController.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(mediaViewControllerDismissed)))
            collectionViewController.present(mediaViewController, animated: false)
        }
    }

    func configure(message: Message, collectionViewController: JSQMessagesViewController) {
        self.collectionViewController = collectionViewController

        avatarImageView.image = #imageLiteral(resourceName: "profile-image-placeholder")
        if let profileImageUrl = message.senderProfileImageUrl {
            avatarImageView.sd_setImage(with: profileImageUrl, completed: { image, err, cacheType, url in
                logInfo("load avatar image view")
            })
        }

        cellBottomLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 12.0)!
        cellBottomLabel.textColor = .white
        cellBottomLabel.text = message.elapsedTimeStringAbbreviated
        cellBottomLabel.textInsets = .zero
        cellBottomLabel.setNeedsDisplay()

        messageBubbleTopLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 16.0)!
        messageBubbleTopLabel.textColor = .white
        messageBubbleTopLabel.text = message.senderName
        messageBubbleTopLabel.textInsets = .zero
        messageBubbleTopLabel.sizeToFit()
        messageBubbleTopLabel.setNeedsDisplay()
        messageBubbleTopLabel.isHidden = true

        textView?.frame.origin = .zero
        textView?.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        if message.recipientId == currentUser.id {
            textView?.backgroundColor = UIColor("4a4a4a").withAlphaComponent(0.5)
        }

        if !message.isMediaMessage() {
            mediaImageView?.alpha = 0.0
            mediaImageView?.image = nil

            if let textView = textView {
                textView.frame = textView.superview!.bounds
                textView.font = textView.font!.withSize(16.0)
            }

            textView?.textColor = .white
            textView?.sizeToFit()

            if let containerView = textView?.superview, message.senderID == currentUser.id {
                textView?.frame.origin = CGPoint(x: containerView.frame.width - self.textView!.frame.width, y: 0.0)
            }

            textView?.alpha = 1.0
        } else {
            textView?.alpha = 0.0

            mediaImageView?.sd_setImage(with: URL(string: message.mediaUrl), placeholderImage: nil)
            mediaImageView?.alpha = 1.0

            messageBubbleContainerView?.gestureRecognizers?.forEach { removeGestureRecognizer($0) }
            messageBubbleContainerView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(mediaContainerViewTapped)))
        }
    }
}
