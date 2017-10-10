//
//  MessagesCollectionViewFlowLayout.swift
//  provide
//
//  Created by Kyle Thomas on 2/18/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class MessagesCollectionViewFlowLayout: JSQMessagesCollectionViewFlowLayout {

    override func sizeForItem(at indexPath: IndexPath!) -> CGSize {
        let width = collectionView.width - 40.0
        let height = 35.0 + messageBubbleSizeForItem(at: indexPath).height
        return CGSize(width: width, height: height)
    }

    override func messageBubbleSizeForItem(at indexPath: IndexPath!) -> CGSize {
        let messageData = collectionView.dataSource.collectionView(collectionView, messageDataForItemAt: indexPath)!
        var width = collectionView.width
        var height: CGFloat = 120.0
        if !messageData.isMediaMessage(), let msg = messageData.text?() {
            let inset = messageBubbleTextViewFrameInsets.left + messageBubbleTextViewFrameInsets.right + messageBubbleTextViewTextContainerInsets.left + messageBubbleTextViewTextContainerInsets.right
            height = MessageCell.heightForMessageBubble(message: msg, width: width - 45.0 - 8.0 - inset)
        } else if messageData.media?() != nil {
            width *= 0.80
            height = width / (16.0 / 9.0)
        }
        return CGSize(width: width, height: height)
    }
}
