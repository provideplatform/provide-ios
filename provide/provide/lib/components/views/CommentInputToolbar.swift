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
import FontAwesomeKit

class CommentInputToolbar: UIToolbar, UITextFieldDelegate, CameraViewControllerDelegate {

    weak var commentsViewController: CommentsViewController!

    @IBOutlet fileprivate weak var commentInputTextFieldBarButtonItem: UIBarButtonItem!
    @IBOutlet fileprivate weak var commentInputTextField: UITextField!

    fileprivate weak var commentInputAccessoryTextField: UITextField! {
        if let commentInputTextField = commentInputTextField, let accessoryToolbar = commentInputTextField.inputAccessoryView {
            return (accessoryToolbar as! CommentInputToolbar).items!.first!.customView as! UITextField
        }

        return nil
    }

    fileprivate var commentInputTextFieldItem: UIBarButtonItem! {
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

    fileprivate var saveItem: UIBarButtonItem! {
        let saveIconImage = FAKFontAwesome.saveIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0)).withRenderingMode(.alwaysTemplate)
        let saveItem = UIBarButtonItem(image: saveIconImage, style: .plain, target: self, action: #selector(addComment(_:)))
        saveItem.tintColor = Color.applicationDefaultBarButtonItemTintColor()
        return saveItem
    }

    fileprivate var photoItem: UIBarButtonItem! {
        let photoItemImage = FAKFontAwesome.cameraIcon(withSize: 25.0).image(with: CGSize(width: 25.0, height: 25.0)).withRenderingMode(.alwaysTemplate)
        let photoItem = UIBarButtonItem(image: photoItemImage, style: .plain, target: self, action: #selector(addPhoto(_:)))
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

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow.rawValue)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow.rawValue)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: NSNotification.Name.UIKeyboardDidHide.rawValue)
    }

    func dismiss() {
        if let commentInputTextField = commentInputTextField, commentInputTextField.isFirstResponder {
            commentInputTextField.resignFirstResponder()
        }
    }

    func clipToBounds(_ bounds: CGRect) {
        var offset: CGFloat = 80.0 // account for bar item margins
        if let items = items {
            for item in items where item != commentInputTextFieldBarButtonItem {
                offset += item.width + 25.0
            }
        }

        commentInputTextField.frame.size.width = bounds.width - offset
        commentInputTextFieldBarButtonItem.width = commentInputTextField.width

        sizeToFit()

        DispatchQueue.main.async {
            let toolbar = CommentInputToolbar(frame: self.frame.offsetBy(dx: 0.0, dy: self.height))
            toolbar.barTintColor = self.barTintColor
            toolbar.commentsViewController = self.commentsViewController

            let commentInputTextFieldItem = self.commentInputTextFieldItem
            toolbar.items = [commentInputTextFieldItem!, self.saveItem, self.photoItem]

            self.commentInputTextField.inputAccessoryView = toolbar
        }
    }

    func addPhoto(_ sender: UIBarButtonItem!) {
        let cameraViewController = UIStoryboard("Camera").instantiateInitialViewController() as! CameraViewController
        cameraViewController.delegate = self

        commentsViewController.present(cameraViewController, animated: true)
    }

    func addComment(_ sender: UIBarButtonItem!) {
        var comment: String!
        var textField: UITextField!

        if let commentInputAccessoryTextField = commentInputAccessoryTextField {
            comment = commentInputAccessoryTextField.text
            textField = commentInputAccessoryTextField
        } else if let commentInputTextField = commentInputTextField {
            comment = commentInputTextField.text
            textField = commentInputTextField
        }

        if textField != nil && textField.isFirstResponder {
            textField.resignFirstResponder()
        }

        if let comment = comment {
            if comment.length > 0 {
                commentInputTextField.text = ""
                commentsViewController?.commentsViewControllerDelegate?.commentsViewController(commentsViewController, shouldCreateComment: comment, withImageAttachment: nil)
            }
        }
    }

    func disable() {
        commentInputTextField?.isEnabled = false
        items?.forEach { $0.isEnabled = false }
    }

    func enable() {
        commentInputTextField?.isEnabled = true
        items?.forEach { $0.isEnabled = true }
    }

    func keyboardWillShow() {
        if let commentInputTextField = commentInputTextField, let accessoryToolbar = commentInputTextField.inputAccessoryView, accessoryToolbar is CommentInputToolbar {
            let commentInputTextField = (accessoryToolbar as! CommentInputToolbar).items!.first!.customView as! UITextField
            commentInputTextField.text = self.commentInputTextField.text
            commentInputTextField.becomeFirstResponder()
        }
    }

    func keyboardDidShow() {

    }

    func keyboardDidHide() {

    }

    // MARK: UITextFieldDelegate

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let comment = textField.text, comment.length > 0 {
            addComment(nil)
            return true
        }

        return false
    }

    // MARK: CameraViewControllerDelegate

    func outputModeForCameraViewController(_ viewController: CameraViewController) -> CameraOutputMode {
        return .photo
    }

    func cameraViewControllerDidBeginAsyncStillImageCapture(_ viewController: CameraViewController) {
        cameraViewControllerCanceled(viewController)
    }

    func cameraViewController(_ viewController: CameraViewController, didCaptureStillImage image: UIImage) {
        commentsViewController?.commentsViewControllerDelegate?.commentsViewController(commentsViewController, shouldCreateComment: "", withImageAttachment: image)
    }

    func cameraViewControllerCanceled(_ viewController: CameraViewController) {
        commentsViewController?.dismiss(animated: false)
    }

    func cameraViewController(_ viewController: CameraViewController, didSelectImageFromCameraRoll image: UIImage) {

    }

    func cameraViewControllerDidOutputFaceMetadata(_ viewController: CameraViewController, metadataFaceObject: AVMetadataFaceObject) {

    }

    func cameraViewControllerShouldOutputFaceMetadata(_ viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerShouldRenderFacialRecognition(_ viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerShouldOutputOCRMetadata(_ viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewController(_ cameraViewController: CameraViewController, didStartVideoCaptureAtURL fileURL: URL) {

    }

    func cameraViewController(_ cameraViewController: CameraViewController, didFinishVideoCaptureAtURL fileURL: URL) {

    }

    func cameraViewController(_ viewController: CameraViewController, didRecognizeText text: String!) {

    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
