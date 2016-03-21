//
//  CommentInputToolbar.swift
//  provide
//
//  Created by Kyle Thomas on 3/21/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class CommentInputToolbar: UIToolbar {

    weak var commentsViewController: CommentsViewController!

    @IBOutlet private weak var commentInputTextFieldBarButtonItem: UIBarButtonItem!
    @IBOutlet private weak var commentInputTextField: UITextField!

    private var saveItem: UIBarButtonItem! {
        let saveIconImage = FAKFontAwesome.saveIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0)).imageWithRenderingMode(.AlwaysTemplate)
        let saveItem = UIBarButtonItem(image: saveIconImage, style: .Plain, target: self, action: "addComment:")
        saveItem.tintColor = Color.applicationDefaultBarButtonItemTintColor()
        return saveItem
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        items!.append(saveItem)
    }

    func clipToBounds(bounds: CGRect) {
        var offset: CGFloat = 40.0 // account for bar item margins
        if let items = items {
            for item in items {
                if item != commentInputTextFieldBarButtonItem {
                    offset += item.width + 25.0
                }
            }
        }

        commentInputTextField.frame.size.width = bounds.size.width - offset
        commentInputTextFieldBarButtonItem.width = commentInputTextField.frame.size.width
    }

    func addComment(sender: UIBarButtonItem!) {
        if let comment = commentInputTextField?.text {
            if comment.length > 0 {
                commentsViewController?.commentsViewControllerDelegate?.commentsViewController(commentsViewController, shouldCreateComment: comment)
            }
        }
    }
}
