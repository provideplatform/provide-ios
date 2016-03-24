//
//  ExpenseCaptureViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/5/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit
import AVFoundation

protocol ExpenseCaptureViewControllerDelegate {
    func expensableForExpenseCaptureViewController(viewController: ExpenseCaptureViewController) -> Model
    func expenseCaptureViewControllerBeganCreatingExpense(viewController: ExpenseCaptureViewController)
    func expenseCaptureViewController(viewController: ExpenseCaptureViewController, didCaptureReceipt receipt: UIImage, recognizedTexts texts: [String]!)
    func expenseCaptureViewController(viewController: ExpenseCaptureViewController, didCreateExpense expense: Expense)
}

class ExpenseCaptureViewController: CameraViewController, CameraViewControllerDelegate, ExpenseEditorViewControllerDelegate {

    var expenseCaptureViewControllerDelegate: ExpenseCaptureViewControllerDelegate!

    private var capturedReceipt: UIImage!

    private var recognizedTexts = [String]()

    private var recognizedAmount: Double {
        for recognizedText in recognizedTexts.reverse() {
            let matches = Regex.match("\\d+\\.\\d{2}", input: recognizedText)
            if matches.count > 0 {
                let match = matches[0]
                let range = Range<String.Index>(start: recognizedText.startIndex.advancedBy(match.range.length), end: recognizedText.endIndex)
                return Double(recognizedText.substringWithRange(range))!
            }
        }
        return 0.0
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationItem()

        view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier! == "ExpenseEditorViewControllerSegue" {
            (segue.destinationViewController as! ExpenseEditorViewController).delegate = self

            let expense = Expense()
            expense.incurredAtString = NSDate().format("yyyy-MM-dd'T'HH:mm:ssZZ")
            expense.desc = recognizedTexts.joinWithSeparator("\n")
            expense.amount = recognizedAmount
            expense.attachments = [Attachment]()
            expense.receiptImage = capturedReceipt
            if let expensable = expenseCaptureViewControllerDelegate?.expensableForExpenseCaptureViewController(self) {
                expense.expensableType = expensable.isKindOfClass(WorkOrder) ? "work_order" : (expensable.isKindOfClass(Job) ? "job" : nil)
                expense.expensableId = expensable.isKindOfClass(WorkOrder) ? (expensable as! WorkOrder).id : (expensable.isKindOfClass(Job) ? (expensable as! Job).id : 0)
            }
            (segue.destinationViewController as! ExpenseEditorViewController).expense = expense
        }
    }

    override func setupNavigationItem() {
        navigationItem.title = "CAPTURE RECEIPT"
        navigationItem.hidesBackButton = true

        navigationItem.leftBarButtonItem = UIBarButtonItem.plainBarButtonItem(title: "CANCEL", target: self, action: Selector("dismiss:"))
    }

    // MARK: CameraViewControllerDelegate

    func outputModeForCameraViewController(viewController: CameraViewController) -> CameraOutputMode {
        return .Photo
    }

    func cameraViewControllerCanceled(viewController: CameraViewController) {
        if let presentingViewController = presentingViewController {
            presentingViewController.dismissViewController(animated: true)
        }
    }

    func cameraViewControllerDidBeginAsyncStillImageCapture(viewController: CameraViewController) {

    }

    func cameraViewController(viewController: CameraViewController, didCaptureStillImage image: UIImage) {
        expenseCaptureViewControllerDelegate?.expenseCaptureViewController(self, didCaptureReceipt: image, recognizedTexts: recognizedTexts)
        capturedReceipt = image

        performSegueWithIdentifier("ExpenseEditorViewControllerSegue", sender: self)
    }

    func cameraViewController(viewController: CameraViewController, didSelectImageFromCameraRoll image: UIImage) {

    }

    func cameraViewController(cameraViewController: CameraViewController, didStartVideoCaptureAtURL fileURL: NSURL) {

    }

    func cameraViewController(cameraViewController: CameraViewController, didFinishVideoCaptureAtURL fileURL: NSURL) {

    }

    func cameraViewControllerShouldOutputFaceMetadata(viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerShouldOutputOCRMetadata(viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerShouldRenderFacialRecognition(viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerDidOutputFaceMetadata(viewController: CameraViewController, metadataFaceObject: AVMetadataFaceObject) {

    }

    func cameraViewController(viewController: CameraViewController, didRecognizeText text: String!) {
        recognizedTexts.append(text)
    }

    // MARK: ExpenseEditorViewControllerDelegate

    func expenseEditorViewControllerBeganCreatingExpense(viewController: ExpenseEditorViewController) {
        cameraViewControllerCanceled(self)
        expenseCaptureViewControllerDelegate?.expenseCaptureViewControllerBeganCreatingExpense(self)
    }

    func expenseEditorViewController(viewController: ExpenseEditorViewController, didCreateExpense expense: Expense) {
        expenseCaptureViewControllerDelegate?.expenseCaptureViewController(self, didCreateExpense: expense)

        capturedReceipt = nil
        recognizedTexts = [String]()
    }

    func expenseEditorViewController(viewController: ExpenseEditorViewController, didFailToCreateExpenseWithStatusCode statusCode: Int) {
        // TODO: Add appropriate delegation

        capturedReceipt = nil
        recognizedTexts = [String]()
    }
}
