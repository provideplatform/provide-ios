//
//  MessagesViewController.swift
//  provide
//
//  Created by Jawwad Ahmad on 5/30/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class MessagesViewController: JSQMessagesViewController {

    fileprivate var messages = [Message]()

    override func viewDidLoad() {
        super.viewDidLoad()

        if let navigationController = navigationController {
            let backgroundImage = Color.applicationDefaultNavigationBarBackgroundImage()

            navigationController.navigationBar.setBackgroundImage(backgroundImage, for: .default)
            navigationController.navigationBar.titleTextAttributes = AppearenceProxy.navBarTitleTextAttributes()
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "DISMISS", style: .plain, target: self, action: #selector(MessagesViewController.dismiss(_:)))
        }

        title = "MESSAGES"

        // Must set senderId and senderDisplayName
        senderId = currentUser.id.description
        senderDisplayName = currentUser.name

        // Hide the media attachment button
        inputToolbar!.contentView!.leftBarButtonItem = nil

        // No avatars for now
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero

        automaticallyScrollsToMostRecentMessage = true

        fetchMessages()
    }

    fileprivate func fetchMessages() {
        MessageService.sharedService().fetch(
            onMessagesFetched: { messages in
                self.messages += messages
                self.collectionView!.reloadData()
                self.scrollToBottom(animated: false)
            },
            onError: { error, statusCode, responseString in
                // TODO
            }
        )
    }

    @objc fileprivate func dismiss(_: UIBarButtonItem) {
        dismissViewController(true)
    }

    // MARK: - Observe NewMessageReceivedNotification

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(MessagesViewController.newMessageReceived(_:)), name: "NewMessageReceivedNotification")
    }

    @objc fileprivate func newMessageReceived(_ notification: Notification) {
        let message = notification.object as! Message
        messages.append(message)
        collectionView!.reloadData()
        scrollToBottom(animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - JSQMessagesViewController method overrides

    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {

        // 1. Play Sound
        JSQSystemSoundPlayer.jsq_playMessageSentSound()

        // 2. Create temporary local mesasge and append to data source
        let message = Message(text: text, recipientId: lastDispatcherId())
        message.createdAt = date
        message.senderID = currentUser.id
        message.senderName = currentUser.name
        messages.append(message)

        // 3. Finish
        finishSendingMessage(animated: true)

        // 4. Post the message
        MessageService.sharedService().createMessage(text, recipientId: lastDispatcherId(),
            onMessageCreated: { message in
                self.messages.removeLast() // remove the temp
                self.messages.append(message) // add the real
                self.collectionView!.reloadData()
            },
            onError: { error, statusCode, responseString in
                // TODO: Handle error
            }
        )
    }

    // Find the last dispatcher that a message was received from
    fileprivate func lastDispatcherId() -> Int {
        let notSentByMe = messages.filter { $0.senderId() != self.senderId }
        return notSentByMe.last!.senderID
    }

    // MARK: - UICollectionView

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell

        let message = messages[(indexPath as NSIndexPath).row]
        cell.textView!.textColor = isFromCurrentUser(message) ? UIColor.white : UIColor.black
        // TODO: cell.textView!.linkTextAttributes = [NSForegroundColorAttributeName: cell.textView!.textColor, NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue]

        return cell
    }

    // MARK: - JSQMessagesCollectionView overrides

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }

    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleGreen())
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.row]
        return isFromCurrentUser(message) ? outgoingBubble : incomingBubble
    }

    // Set the avatar image for the incomming and outgoing messages
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }

    // For name above incoming message bubbles
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.row]

        if isFromCurrentUser(message) || isFromPreviousSender(message, atIndex: indexPath.item) {
            return nil
        } else {
            return NSAttributedString(string: "\(message.senderDisplayName()) (\(message.senderId()))")
        }
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        let message = messages[indexPath.row]

        if isFromCurrentUser(message) || isFromPreviousSender(message, atIndex: indexPath.item) {
            return 0.0
        } else {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
    }

    // MARK: - Private

    fileprivate func isFromCurrentUser(_ message: Message) -> Bool {
        return message.senderId() == currentUser.id.description
    }

    fileprivate func isFromPreviousSender(_ message: Message, atIndex messageIndex: Int) -> Bool {
        if messageIndex > 0 {
            let previousMessage = messages[messageIndex - 1]
            if message.senderId() == previousMessage.senderId() {
                return true
            }
        }
        return false
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
