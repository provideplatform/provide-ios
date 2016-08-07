//
//  MessagesViewController.swift
//  provide
//
//  Created by Jawwad Ahmad on 5/30/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit
import JSQMessagesViewController

class MessagesViewController: JSQMessagesViewController {

    private var messages = [Message]()

    override func viewDidLoad() {
        super.viewDidLoad()

        if let navigationController = navigationController {
            let backgroundImage = Color.applicationDefaultNavigationBarBackgroundImage()

            navigationController.navigationBar.setBackgroundImage(backgroundImage, forBarMetrics: .Default)
            navigationController.navigationBar.titleTextAttributes = AppearenceProxy.navBarTitleTextAttributes()
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "DISMISS", style: .Plain, target: self, action: #selector(MessagesViewController.dismiss(_:)))
        }

        title = "MESSAGES"

        // Must set senderId and senderDisplayName
        senderId = currentUser().id.description
        senderDisplayName = currentUser().name

        // Hide the media attachment button
        inputToolbar!.contentView!.leftBarButtonItem = nil

        // No avatars for now
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero

        automaticallyScrollsToMostRecentMessage = true

        fetchMessages()
    }

    private func fetchMessages() {
        MessageService.sharedService().fetch(
            onMessagesFetched: { messages in
                self.messages += messages
                self.collectionView!.reloadData()
                self.scrollToBottomAnimated(false)
            },
            onError: { error, statusCode, responseString in
                // TODO
            }
        )
    }

    @objc private func dismiss(_: UIBarButtonItem) {
        dismissViewController(animated: true)
    }

    // MARK: - Observe NewMessageReceivedNotification

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MessagesViewController.newMessageReceived(_:)), name: "NewMessageReceivedNotification")
    }

    @objc private func newMessageReceived(notification: NSNotification) {
        let message = notification.object as! Message
        messages.append(message)
        collectionView!.reloadData()
        scrollToBottomAnimated(true)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: - JSQMessagesViewController method overrides

    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {

        // 1. Play Sound
        JSQSystemSoundPlayer.jsq_playMessageSentSound()

        // 2. Create temporary local mesasge and append to data source
        let message = Message(text: text, recipientId: lastDispatcherId())
        message.createdAt = date
        message.senderID = currentUser().id
        message.senderName = currentUser().name
        messages.append(message)

        // 3. Finish
        finishSendingMessageAnimated(true)

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
    private func lastDispatcherId() -> Int {
        let notSentByMe = messages.filter { $0.senderId() != self.senderId }
        return notSentByMe.last!.senderID
    }

    // MARK: - UICollectionView

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell

        let message = messages[indexPath.row]
        cell.textView!.textColor = isFromCurrentUser(message) ? UIColor.whiteColor() : UIColor.blackColor()
        // TODO: cell.textView!.linkTextAttributes = [NSForegroundColorAttributeName: cell.textView!.textColor, NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue]

        return cell
    }

    // MARK: - JSQMessagesCollectionView overrides

    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }

    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())

    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.row]
        return isFromCurrentUser(message) ? outgoingBubble : incomingBubble
    }

    // Set the avatar image for the incomming and outgoing messages
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }

    // For name above incoming message bubbles
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.row]

        if isFromCurrentUser(message) || isFromPreviousSender(message, atIndex: indexPath.item) {
            return nil
        } else {
            return NSAttributedString(string: "\(message.senderDisplayName()) (\(message.senderId()))")
        }
    }

    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let message = messages[indexPath.row]

        if isFromCurrentUser(message) || isFromPreviousSender(message, atIndex: indexPath.item) {
            return 0.0
        } else {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
    }

    // MARK: - Private

    private func isFromCurrentUser(message: Message) -> Bool {
        return message.senderId() == currentUser().id.description
    }

    private func isFromPreviousSender(message: Message, atIndex messageIndex: Int) -> Bool {
        if messageIndex > 0 {
            let previousMessage = messages[messageIndex - 1]
            if message.senderId() == previousMessage.senderId() {
                return true
            }
        }
        return false
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
