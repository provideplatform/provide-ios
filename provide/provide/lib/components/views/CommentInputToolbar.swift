//
//  CommentInputToolbar.swift
//  provide
//
//  Created by Kyle Thomas on 3/21/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class CommentInputToolbar: UIToolbar, UITextFieldDelegate, CameraViewControllerDelegate {

    weak var commentsViewController: CommentsViewController!

    @IBOutlet private weak var commentInputTextFieldBarButtonItem: UIBarButtonItem!
    @IBOutlet private weak var commentInputTextField: UITextField!

    private weak var commentInputAccessoryTextField: UITextField! {
        if let commentInputTextField = commentInputTextField {
            if let accessoryToolbar = commentInputTextField.inputAccessoryView {
                return (accessoryToolbar as! CommentInputToolbar).items!.first!.customView as! UITextField
            }
        }

        return nil
    }

    private var commentInputTextFieldItem: UIBarButtonItem! {
        let textField = UITextField(frame: commentInputTextField.bounds)
        textField.delegate = self
        textField.enablesReturnKeyAutomatically = commentInputTextField.enablesReturnKeyAutomatically
        textField.returnKeyType = commentInputTextField.returnKeyType
        textField.text = commentInputTextField.text
        textField.placeholder = commentInputTextField.placeholder
        textField.backgroundColor = commentInputTextField.backgroundColor
        textField.font = commentInputTextField.font
        textField.borderStyle = commentInputTextField.borderStyle
        let commentInputTextFieldItem = UIBarButtonItem(customView: textField)
        return commentInputTextFieldItem
    }

    private var saveItem: UIBarButtonItem! {
        let saveIconImage = FAKFontAwesome.saveIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0)).imageWithRenderingMode(.AlwaysTemplate)
        let saveItem = UIBarButtonItem(image: saveIconImage, style: .Plain, target: self, action: #selector(CommentInputToolbar.addComment(_:)))
        saveItem.tintColor = Color.applicationDefaultBarButtonItemTintColor()
        return saveItem
    }

    private var photoItem: UIBarButtonItem! {
        let photoItemImage = FAKFontAwesome.cameraIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0)).imageWithRenderingMode(.AlwaysTemplate)
        let photoItem = UIBarButtonItem(image: photoItemImage, style: .Plain, target: self, action: #selector(CommentInputToolbar.addPhoto(_:)))
        photoItem.tintColor = Color.applicationDefaultBarButtonItemTintColor()
        return photoItem
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        items!.append(saveItem)
        items!.append(photoItem)

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentInputToolbar.keyboardWillShow), name: UIKeyboardWillShowNotification)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentInputToolbar.keyboardDidShow), name: UIKeyboardDidShowNotification)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CommentInputToolbar.keyboardDidHide), name: UIKeyboardDidHideNotification)
    }

    func dismiss() {
        if let commentInputTextField = commentInputTextField {
            if commentInputTextField.isFirstResponder() {
                commentInputTextField.resignFirstResponder()
            }
        }
    }

    func clipToBounds(bounds: CGRect) {
        var offset: CGFloat = 80.0 // account for bar item margins
        if let items = items {
            for item in items {
                if item != commentInputTextFieldBarButtonItem {
                    offset += item.width + 25.0
                }
            }
        }

        commentInputTextField.frame.size.width = bounds.size.width - offset
        commentInputTextFieldBarButtonItem.width = commentInputTextField.frame.size.width

        sizeToFit()

        dispatch_after_delay(0.0) {
            if !isIPad() {
                let toolbar = CommentInputToolbar(frame: CGRectOffset(self.frame, 0.0, self.frame.height))
                toolbar.barTintColor = self.barTintColor
                toolbar.commentsViewController = self.commentsViewController

                let commentInputTextFieldItem = self.commentInputTextFieldItem
                toolbar.items = [commentInputTextFieldItem, self.saveItem, self.photoItem]

                self.commentInputTextField.inputAccessoryView = toolbar
            }
        }
    }

    func addPhoto(sender: UIBarButtonItem!) {
        let cameraViewController = UIStoryboard("Camera").instantiateInitialViewController() as! CameraViewController
        cameraViewController.delegate = self

        commentsViewController.presentViewController(cameraViewController, animated: true)
    }

    func addComment(sender: UIBarButtonItem!) {
        var comment: String!
        var textField: UITextField!

        if let commentInputAccessoryTextField = commentInputAccessoryTextField {
            comment = commentInputAccessoryTextField.text
            textField = commentInputAccessoryTextField
        } else if let commentInputTextField = commentInputTextField {
            comment = commentInputTextField.text
            textField = commentInputTextField
        }

        if textField != nil && textField.isFirstResponder() {
            textField.resignFirstResponder()
        }

        if let comment = comment {
            if comment.length > 0 {
                commentInputTextField.text = ""
                commentsViewController?.commentsViewControllerDelegate?.commentsViewController(commentsViewController, shouldCreateComment: comment, withImageAttachment: nil)
            }
        }
    }

    func keyboardWillShow() {
        if let commentInputTextField = commentInputTextField {
            if let accessoryToolbar = commentInputTextField.inputAccessoryView {
                if accessoryToolbar is CommentInputToolbar {
                    let commentInputTextField = (accessoryToolbar as! CommentInputToolbar).items!.first!.customView as! UITextField
                    commentInputTextField.text = self.commentInputTextField.text
                    commentInputTextField.becomeFirstResponder()
                }
            }
        }
    }

    func keyboardDidShow() {

    }

    func keyboardDidHide() {

    }

    // MARK: UITextFieldDelegate

    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        return true
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let comment = textField.text {
            if comment.length > 0 {
                addComment(nil)
                return true
            }
        }

        return false
    }

    // MARK: CameraViewControllerDelegate

    func outputModeForCameraViewController(viewController: CameraViewController) -> CameraOutputMode {
        return .Photo
    }

    func cameraViewControllerDidBeginAsyncStillImageCapture(viewController: CameraViewController) {
        cameraViewControllerCanceled(viewController)
    }

    func cameraViewController(viewController: CameraViewController, didCaptureStillImage image: UIImage) {
        commentsViewController?.commentsViewControllerDelegate?.commentsViewController(commentsViewController, shouldCreateComment: "", withImageAttachment: image)
    }

    func cameraViewControllerCanceled(viewController: CameraViewController) {
        commentsViewController?.dismissViewController(animated: false)
    }

    func cameraViewController(viewController: CameraViewController, didSelectImageFromCameraRoll image: UIImage) {

    }

    func cameraViewControllerDidOutputFaceMetadata(viewController: CameraViewController, metadataFaceObject: AVMetadataFaceObject) {

    }

    func cameraViewControllerShouldOutputFaceMetadata(viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerShouldRenderFacialRecognition(viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerShouldOutputOCRMetadata(viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewController(cameraViewController: CameraViewController, didStartVideoCaptureAtURL fileURL: NSURL) {

    }

    func cameraViewController(cameraViewController: CameraViewController, didFinishVideoCaptureAtURL fileURL: NSURL) {
        
    }
    
    func cameraViewController(viewController: CameraViewController, didRecognizeText text: String!) {
        
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
