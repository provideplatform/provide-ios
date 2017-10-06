//
//  MessagesViewController.swift
//  provide
//
//  Created by Kyle Thomas on 2/1/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import JSQMessagesViewController

class MessagesViewController: JSQMessagesViewController {

    private var messages = [Message]()
    private var canceled = false
    private var page = 0
    private var pendingFetch = false
    private var shouldPage = true

    private var selectedImage: UIImage!

    private var recipientId: String!

    var recipient: User! {
        didSet {
            if let recipient = recipient {
                recipientId = String(recipient.id)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigationItemTitleView()

        // Must set senderId and senderDisplayName
        senderId = currentUser.id.description
        senderDisplayName = currentUser.name

        // Hide the media attachment button
        inputToolbar!.contentView!.leftBarButtonItem.tintColor = .white
        inputToolbar!.contentView!.leftBarButtonItem.removeTarget(nil, action: nil, for: .allEvents)
        inputToolbar!.contentView!.leftBarButtonItem.addTarget(self, action: #selector(didPressCameraAccessoryButton), for: .touchUpInside)

        // Setup the keyboard
        keyboardController!.textView.keyboardAppearance = .alert

        // Setup the input toolbar
        inputToolbar!.backgroundColor = .clear
        inputToolbar!.contentView!.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        inputToolbar!.contentView!.leftBarButtonContainerView?.backgroundColor = .clear
        inputToolbar!.contentView!.rightBarButtonContainerView?.backgroundColor = .clear

        // Avatar image size
        let avatarSize = CGSize(width: 30, height: 30)
        collectionView!.collectionViewLayout.incomingAvatarViewSize = avatarSize
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = avatarSize

        incomingCellIdentifier = "InboundMessageCellReuseIdentifier"
        incomingMediaCellIdentifier = "InboundMediaMessageCellReuseIdentifier"
        outgoingCellIdentifier = "OutboundMessageCellReuseIdentifier"
        outgoingMediaCellIdentifier = "OutboundMediaMessageCellReuseIdentifier"

        collectionView.register(UINib(nibName: "InboundMessageCell", bundle: nil),
                                forCellWithReuseIdentifier: "InboundMessageCellReuseIdentifier")

        collectionView.register(UINib(nibName: "InboundMediaMessageCell", bundle: nil),
                                forCellWithReuseIdentifier: "InboundMediaMessageCellReuseIdentifier")

        collectionView.register(UINib(nibName: "OutboundMessageCell", bundle: nil),
                                forCellWithReuseIdentifier: "OutboundMessageCellReuseIdentifier")

        collectionView.register(UINib(nibName: "OutboundMediaMessageCell", bundle: nil),
                                forCellWithReuseIdentifier: "OutboundMediaMessageCellReuseIdentifier")

        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        collectionView.backgroundColor = .clear

        automaticallyScrollsToMostRecentMessage = true

        let collectionViewFlowLayout = MessagesCollectionViewFlowLayout()
        collectionViewFlowLayout.messageBubbleFont = UIFont(name: "HelveticaNeue", size: 14.0)!

        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.setCollectionViewLayout(collectionViewFlowLayout, animated: false)

        fetchMessages()
    }

    private func fetchMessages() {
        if recipientId != nil && !pendingFetch && shouldPage {
            pendingFetch = true

            showHUD()

            let nextPage = page + 1

            if page == 0 {
                collectionView.alpha = 0.0
            }

            let params: [String: Any] = ["recipient_id": recipientId, "page": nextPage]
            MessageService.shared.fetch(params: params as [String : AnyObject], onMessagesFetched: { messages in
                self.hideHUD()

                self.shouldPage = messages.count == 10

                let originalContentSize = self.collectionView.contentSize

                UIView.animate(withDuration: 0.0) {
                    self.collectionView.isScrollEnabled = false
                    self.collectionView.scrollsToTop = false
                    self.collectionView.performBatchUpdates({
                        var indexPaths = [IndexPath]()
                        var i = 0
                        for msg in messages {
                            self.messages.insert(msg, at: 0)
                            indexPaths.append(IndexPath(row: i, section: 0))
                            i += 1
                        }
                        self.collectionView.insertItems(at: indexPaths)
                    }, completion: { _ in
                        self.page = nextPage
                        if self.page == 1 {
                            self.scrollToBottom(animated: false)
                            self.collectionView.alpha = 1.0
                        } else {
                            self.collectionView.contentOffset = CGPoint(x: 0, y: self.collectionView.contentSize.height - originalContentSize.height)
                        }
                        self.collectionView.scrollsToTop = true
                        self.collectionView.isScrollEnabled = true
                        self.pendingFetch = false
                    })
                }
            }, onError: { _, _, _ in
                self.hideHUD()
                self.pendingFetch = false
            })
        }
    }

    private func presentRecipientSearchViewController() {
        logWarn("Recipient search view controller not implemented")
    }

    dynamic private func dismiss(_: UIBarButtonItem) {
        dismiss(animated: true)
    }

    // MARK: - Observe NewMessageReceivedNotification

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NotificationCenter.default.addObserverForName("NewMessageReceivedNotification") { [weak self] notification in
            if let notification = notification {
                self?.newMessageReceived(notification)
            }
        }
    }

    dynamic private func newMessageReceived(_ notification: Notification) {
        if let message = notification.object as? Message {
            messages.append(message) // FIXME: perform update on collection view
            collectionView?.reloadData()
            scrollToBottom(animated: true)
        }
    }

    dynamic private func didPressCameraAccessoryButton(_ notification: AnyObject) {
        presentImagePickerViewController()
    }

    private func presentImagePickerViewController(initialImage: UIImage? = nil) {
        let imagePickerVC = UIImagePickerController()
        imagePickerVC.sourceType = .savedPhotosAlbum
        imagePickerVC.delegate = self
        present(imagePickerVC, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if recipientId == nil && !canceled {
            presentRecipientSearchViewController()
        } else if canceled {
            navigationController?.popViewController(animated: true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        if !navigationController!.viewControllers.contains(self) {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "MessagesViewControllerPoppedNotification"), object: self)
        }
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self) // swiftlint:disable:this notification_center_detachment
    }

    fileprivate func presentConfirmMediaViewController(image: UIImage) {
        selectedImage = image

        let windowWidth = UIApplication.shared.keyWindow!.frame.width
        let windowHeight = UIApplication.shared.keyWindow!.frame.height

        let confirmMediaViewController = UIViewController()
        let mediaImageView = UIImageView()
        mediaImageView.frame = CGRect(x: 0.0, y: 0.0, width: windowWidth, height: windowHeight)
        mediaImageView.center = collectionView.center
        mediaImageView.contentMode = .scaleAspectFit
        mediaImageView.image = image
        confirmMediaViewController.view.addSubview(mediaImageView)

        let cancelButton = UIButton(type: .custom)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.tintColor = .white
        cancelButton.backgroundColor = .clear
        cancelButton.addTarget(self, action: #selector(cancelMediaConfirmation), for: .touchUpInside)
        cancelButton.sizeToFit()
        cancelButton.frame = CGRect(x: (windowWidth * 0.25) - (cancelButton.frame.width / 2.0),
                                    y: windowHeight - cancelButton.frame.height,
                                    width: cancelButton.frame.width,
                                    height: cancelButton.frame.height)
        confirmMediaViewController.view.addSubview(cancelButton)

        let confirmButton = UIButton(type: .custom)
        confirmButton.setTitle("Send", for: .normal)
        confirmButton.tintColor = .white
        confirmButton.backgroundColor = .clear
        confirmButton.addTarget(self, action: #selector(confirmMediaSelectionAndSend), for: .touchUpInside)
        confirmButton.sizeToFit()
        confirmButton.frame = CGRect(x: (windowWidth * 0.75) - (confirmButton.frame.width / 2.0),
                                     y: windowHeight - confirmButton.frame.height,
                                     width: confirmButton.frame.width,
                                     height: confirmButton.frame.height)
        confirmMediaViewController.view.addSubview(confirmButton)

        present(confirmMediaViewController, animated: false)
    }

    dynamic private func cancelMediaConfirmation(sender: UIButton) {
        dismiss(animated: false)
        selectedImage = nil
    }

    dynamic private func confirmMediaSelectionAndSend(sender: UIButton) {
        dismiss(animated: false)
        if let image = selectedImage {
            sendMessage(with: image, senderId: String(currentUser.id), senderDisplayName: currentUser.name, date: Date())
        }
    }

    private func sendMessage(with image: UIImage, senderId: String, senderDisplayName: String, date: Date) {
        //        if let image = image {
        //            let filename = "\(senderId)-image-\(date.timeIntervalSince1970).jpg"

        //            if let data = UIImageJPEGRepresentation(image, 1.0) {
        // TODO: implement ApiService.shared.createAttachment .upload(data, withMimeType: "image/jpeg", toBucket: "blastcal-production", asKey: filename,
        //             onSuccess: { response in
        //                 JSQSystemSoundPlayer.jsq_playMessageSentSound()
        //
        //                 let mediaUrl = "https://blastcal-production.s3.amazonaws.com/\(filename)"
        //                 let message = Message(body: "",
        //                                       mediaUrl: mediaUrl,
        //                                       recipientId: self.lastDispatcherId(),
        //                                       senderId: currentUser.id,
        //                                       senderUsername: currentUser.username)
        //
        //                 self.collectionView.performBatchUpdates({
        //                     self.messages.append(message)
        //                     self.collectionView.insertItems(at: [IndexPath(row: self.messages.count - 1, section: 0)])
        //                 }, completion: nil)
        //
        //                 self.finishSendingMessage(animated: true)
        //
        //                 let params: [String: Any] = ["media_url": mediaUrl, "recipient_id": self.lastDispatcherId()]
        //                 Message.create(params: params, onSuccess: { (msg: Message) in
        //                     self.collectionView.performBatchUpdates({
        //                         let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
        //
        //                         self.messages.remove(at: indexPath.row)
        //                         self.messages.append(msg)
        //                         self.collectionView.reloadItems(at: [indexPath])
        //                     }, completion: nil)
        //                 }, onFailure: {
        //
        //                 })
        //             },
        //             onError: { response, _, error in
        //                 if let error = error {
        //                     logError("Media message upload error: \(error)")
        //                 } else {
        //                     logError("Media message upload error")
        //                 }
        //             }
        //         )
        //     }
        // }
    }

    // MARK: - JSQMessagesViewController method overrides

    override func didPressSend(_ button: UIButton, withMessageText text: String, senderId: String, senderDisplayName: String, date: Date) {
        JSQSystemSoundPlayer.jsq_playMessageSentSound()

        let message = Message(body: text, mediaUrl: nil, recipientId: lastDispatcherId(), senderId: currentUser.id, senderName: currentUser.name)

        collectionView.performBatchUpdates({
            self.messages.append(message)
            self.collectionView.insertItems(at: [IndexPath(row: self.messages.count - 1, section: 0)])
        })

        finishSendingMessage(animated: true)

        MessageService.shared.createMessage(text, recipientId: lastDispatcherId(), onMessageCreated: { (msg: Message) in
            self.collectionView.performBatchUpdates({
                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)

                self.messages.remove(at: indexPath.row)
                self.collectionView.deleteItems(at: [indexPath])

                self.messages.append(msg)
                self.collectionView.insertItems(at: [indexPath])
            })
        }, onError: { _, _, _ in
            logWarn("Failed to send message")
        })
    }

    // Find the last dispatcher that a message was received from
    private func lastDispatcherId() -> Int {
        let notSentByMe = messages.filter { $0.senderId() != senderId }
        if notSentByMe.count == 0 {
            return Int(recipientId)!
        }
        return notSentByMe.last!.senderID
    }

    // MARK: - UICollectionView

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let message = messages[indexPath.row]

        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! MessageCell
        cell.configure(message: message, collectionViewController: self)

        return cell
    }

    // MARK: - JSQMessagesCollectionView overrides

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            fetchMessages()
        }
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageDataForItemAt indexPath: IndexPath) -> JSQMessageData {
        return messages[indexPath.row]
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView, header headerView: JSQMessagesLoadEarlierHeaderView, didTapLoadEarlierMessagesButton sender: UIButton) {
        fetchMessages()
    }

    let messageBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.black.withAlphaComponent(0.8))

    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageBubbleImageDataForItemAt indexPath: IndexPath) -> JSQMessageBubbleImageDataSource? {
        return messageBubble
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView, avatarImageDataForItemAt indexPath: IndexPath) -> JSQMessageAvatarImageDataSource? {
        let placeholderImage = #imageLiteral(resourceName: "profile-image-placeholder")
        return JSQMessagesAvatarImage(avatarImage: placeholderImage, highlightedImage: nil, placeholderImage: placeholderImage)
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForMessageBubbleTopLabelAt indexPath: IndexPath) -> CGFloat {
        return 20.0
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellBottomLabelAt indexPath: IndexPath) -> CGFloat {
        return 17.0
    }

    // MARK: - Private

    private func configureNavigationItemTitleView() {
        navigationController?.navigationBar.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        if let recipient = recipient {
            (navigationItem.titleView as! MessagesTitleView).configure(name: (recipient.firstName ?? recipient.name),
                                                                       profileImageUrl: recipient.profileImageUrl,
                                                                       height: navigationController?.navigationBar.frame.height ?? 64.0)
        }
    }

    private func isFromCurrentUser(_ message: Message) -> Bool {
        return message.senderID == currentUser.id
    }

    private func isFromPreviousSender(_ message: Message, atIndex messageIndex: Int) -> Bool {
        if messageIndex > 0 {
            let previousMessage = messages[messageIndex - 1]
            if message.senderID == previousMessage.senderID {
                return true
            }
        }
        return false
    }
}

// MARK: - UIImagePickerControllerDelegate

extension MessagesViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String: Any]) {
        dismiss(animated: true)
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        presentConfirmMediaViewController(image: image)
        //self.sendMessage(with: image, senderId: String(currentUser.id), senderDisplayName: currentUser.username, date: Date())
    }
}
