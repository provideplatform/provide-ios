//
//  ExpenseCaptureViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/5/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import AVFoundation
import KTSwiftExtensions

protocol ExpenseCaptureViewControllerDelegate {
    func expensableForExpenseCaptureViewController(_ viewController: ExpenseCaptureViewController) -> Model
    func expenseCaptureViewControllerBeganCreatingExpense(_ viewController: ExpenseCaptureViewController)
    func expenseCaptureViewController(_ viewController: ExpenseCaptureViewController, didCaptureReceipt receipt: UIImage, recognizedTexts texts: [String]!)
    func expenseCaptureViewController(_ viewController: ExpenseCaptureViewController, didCreateExpense expense: Expense)
}

class ExpenseCaptureViewController: CameraViewController, CameraViewControllerDelegate, ExpenseEditorViewControllerDelegate {

    var expenseCaptureViewControllerDelegate: ExpenseCaptureViewControllerDelegate!

    fileprivate var capturedReceipt: UIImage!

    fileprivate var recognizedTexts = [String]()

    fileprivate var recognizedAmount: Double {
        for recognizedText in recognizedTexts.reversed() {
            let matches = KTRegex.match("\\d+\\.\\d{2}", input: recognizedText)
            if matches.count > 0 {
                let match = matches[0]
                let range = recognizedText.index(recognizedText.startIndex, offsetBy: match.range.length)..<recognizedText.endIndex
                return Double(recognizedText.substring(with: range))!
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

        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier! == "ExpenseEditorViewControllerSegue" {
            (segue.destination as! ExpenseEditorViewController).delegate = self

            let expense = Expense()
            expense.incurredAtString = Date().format("yyyy-MM-dd'T'HH:mm:ssZZ")
            expense.desc = recognizedTexts.joined(separator: "\n")
            expense.amount = recognizedAmount
            expense.attachments = [Attachment]()
            expense.receiptImage = capturedReceipt
            if let expensable = expenseCaptureViewControllerDelegate?.expensableForExpenseCaptureViewController(self) {
                expense.expensableType = expensable.isKind(of: WorkOrder.self) ? "work_order" : (expensable.isKind(of: Job.self) ? "job" : nil)
                expense.expensableId = expensable.isKind(of: WorkOrder.self) ? (expensable as! WorkOrder).id : (expensable.isKind(of: Job.self) ? (expensable as! Job).id : 0)
            }
            (segue.destination as! ExpenseEditorViewController).expense = expense
        }
    }

    override func setupNavigationItem() {
        navigationItem.title = "CAPTURE RECEIPT"
        navigationItem.hidesBackButton = true

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "CANCEL", style: .plain, target: self, action: #selector(ExpenseCaptureViewController.dismiss(_:)))
    }

    // MARK: CameraViewControllerDelegate

    func outputModeForCameraViewController(_ viewController: CameraViewController) -> CameraOutputMode {
        return .photo
    }

    func cameraViewControllerCanceled(_ viewController: CameraViewController) {
        if let presentingViewController = presentingViewController {
            presentingViewController.dismissViewController(true)
        }
    }

    func cameraViewControllerDidBeginAsyncStillImageCapture(_ viewController: CameraViewController) {

    }

    func cameraViewController(_ viewController: CameraViewController, didCaptureStillImage image: UIImage) {
        expenseCaptureViewControllerDelegate?.expenseCaptureViewController(self, didCaptureReceipt: image, recognizedTexts: recognizedTexts)
        capturedReceipt = image

        performSegue(withIdentifier: "ExpenseEditorViewControllerSegue", sender: self)
    }

    func cameraViewController(_ viewController: CameraViewController, didSelectImageFromCameraRoll image: UIImage) {

    }

    func cameraViewController(_ cameraViewController: CameraViewController, didStartVideoCaptureAtURL fileURL: URL) {

    }

    func cameraViewController(_ cameraViewController: CameraViewController, didFinishVideoCaptureAtURL fileURL: URL) {

    }

    func cameraViewControllerShouldOutputFaceMetadata(_ viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerShouldOutputOCRMetadata(_ viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerShouldRenderFacialRecognition(_ viewController: CameraViewController) -> Bool {
        return false
    }

    func cameraViewControllerDidOutputFaceMetadata(_ viewController: CameraViewController, metadataFaceObject: AVMetadataFaceObject) {

    }

    func cameraViewController(_ viewController: CameraViewController, didRecognizeText text: String!) {
        recognizedTexts.append(text)
    }

    // MARK: ExpenseEditorViewControllerDelegate

    func expenseEditorViewControllerBeganCreatingExpense(_ viewController: ExpenseEditorViewController) {
        cameraViewControllerCanceled(self)
        expenseCaptureViewControllerDelegate?.expenseCaptureViewControllerBeganCreatingExpense(self)
    }

    func expenseEditorViewController(_ viewController: ExpenseEditorViewController, didCreateExpense expense: Expense) {
        expenseCaptureViewControllerDelegate?.expenseCaptureViewController(self, didCreateExpense: expense)

        capturedReceipt = nil
        recognizedTexts = [String]()
    }

    func expenseEditorViewController(_ viewController: ExpenseEditorViewController, didFailToCreateExpenseWithStatusCode statusCode: Int) {
        // TODO: Add appropriate delegation

        capturedReceipt = nil
        recognizedTexts = [String]()
    }
}
