//
//  JobBlueprintsViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class JobBlueprintsViewController: ViewController,
                                   BlueprintsPageViewControllerDelegate {

    private var blueprintPreviewBackgroundColor = UIColor(red: 0.11, green: 0.29, blue: 0.565, alpha: 0.45)

    @IBOutlet private weak var blueprintPreviewContainerView: UIView! {
        didSet {
            if let blueprintPreviewContainerView = blueprintPreviewContainerView {
                blueprintPreviewContainerView.backgroundColor = blueprintPreviewBackgroundColor
            }
        }
    }
    @IBOutlet private weak var blueprintActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var blueprintPreviewStatusLabel: UILabel! {
        didSet {
            if let blueprintPreviewStatusLabel = blueprintPreviewStatusLabel {
                blueprintPreviewStatusLabel.text = ""
                blueprintPreviewStatusLabel.alpha = 0.0
            }
        }
    }

    @IBOutlet private weak var blueprintPreviewImageView: UIImageView!

    @IBOutlet private weak var blueprintPagesContainerView: UIView!
    @IBOutlet private weak var estimatesContainerView: UIView!
    @IBOutlet private weak var floorplansContainerView: UIView!

    @IBOutlet private weak var importInstructionsContainerView: UIView!
    @IBOutlet private weak var importInstructionsLabel: UILabel!

    @IBOutlet private weak var importFromDropboxIconButton: UIButton!
    @IBOutlet private weak var importFromDropboxTextButton: UIButton!

    private weak var blueprintsPageViewController: BlueprintsPageViewController!
    private weak var blueprintViewController: BlueprintViewController!

    private var reloadingBlueprint = false
    private var reloadingJob = false
    private var importedPdfAttachment: Attachment! {
        didSet {
            if let _ = importedPdfAttachment {
                hideDropbox()
                importStatus = "Importing your blueprint..."
            }
        }
    }
    private var importedPngAttachment: Attachment! {
        didSet {
            if let _ = importedPngAttachment {
                importStatus = "Generating high-fidelity blueprint representation (this may take up to a few minutes)"
            }
        }
    }
    private var importStatus: String! {
        didSet {
            if let importStatus = importStatus {
                view.sendSubviewToBack(importInstructionsContainerView)
                importInstructionsContainerView.alpha = 0.0

                blueprintActivityIndicatorView.startAnimating()
                blueprintPreviewStatusLabel?.text = importStatus
                blueprintPreviewStatusLabel?.alpha = 1.0
                blueprintPreviewContainerView?.bringSubviewToFront(blueprintPreviewStatusLabel)
                blueprintPreviewContainerView?.alpha = 1.0
            } else {
                blueprintPreviewStatusLabel?.text = ""
            }
        }
    }

    var job: Job! {
        didSet {
            if let _ = job {
                if viewLoaded {
                    refresh()
                }
            }
        }
    }

    private var hasBlueprintScale: Bool {
        if let blueprint = job?.blueprint {
            if let _ = blueprint.metadata["scale"] as? Double {
                return true
            }
        }
        return false
    }

    private var viewLoaded = false

    private var floorplanImportTimer: NSTimer!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        //tabBarItem.image = FAKFontAwesome.photoIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = ""

        importInstructionsLabel?.text = ""
        importInstructionsContainerView?.alpha = 0.0
        importInstructionsContainerView?.superview?.bringSubviewToFront(importInstructionsContainerView)

        estimatesContainerView?.alpha = 0.0
        estimatesContainerView?.superview?.bringSubviewToFront(estimatesContainerView)

        floorplansContainerView?.alpha = 0.0
        floorplansContainerView?.superview?.bringSubviewToFront(floorplansContainerView)

        blueprintPreviewImageView?.alpha = 0.0
        blueprintPreviewImageView?.contentMode = .ScaleAspectFit

        for importFromDropboxButton in [importFromDropboxIconButton, importFromDropboxTextButton] {
            importFromDropboxButton.addTarget(self, action: #selector(JobBlueprintsViewController.importFromDropbox(_:)), forControlEvents: .TouchUpInside)
        }

        hideDropbox()

        NSNotificationCenter.defaultCenter().addObserverForName("AttachmentChanged") { notification in
            if let userInfo = notification.object as? [String : AnyObject] {
                let attachmentId = userInfo["attachment_id"] as? Int
                let attachableType = userInfo["attachable_type"] as? String
                let attachableId = userInfo["attachable_id"] as? Int

                if attachmentId != nil && attachableType != nil && attachableId != nil {
                    if let job = self.job {
                        if attachableType == "job" && attachableId == job.id {
                            self.refresh()
//                            if let importedPdfAttachment = self.importedPdfAttachment {
//                                if importedPdfAttachment.id == attachmentId {
//                                    self.importStatus = "Processing your imported blueprint..."
//                                } else if self.importedPngAttachment == nil {
//                                    self.importedPngAttachment = Attachment()
//                                    self.importedPngAttachment.id = attachmentId!
//                                } else if self.importedPngAttachment.id == attachmentId {
//                                    self.refresh()
//                                }
//                            } else {
//                                self.refresh()
//                            }
                        }
                    }
                }
            }
        }

        if job != nil {
            refresh()
        }

        viewLoaded = true
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        teardownBlueprintViewController()
    }

    func teardown() -> UIImage? {
        blueprintPreviewImageView?.image = nil
        return teardownBlueprintViewController()
    }

    func teardownBlueprintViewController() -> UIImage? {
        return blueprintViewController?.teardown()
    }

    func refresh() {
        if !reloadingJob {
            if let job = job {
                reloadingJob = true

                job.reload(
                    onSuccess: { statusCode, mappingResult in
                        self.blueprintsPageViewController?.resetViewControllers()
                        self.reloadingJob = false

                        self.blueprintPagesContainerView?.alpha = 1.0
                        self.blueprintActivityIndicatorView?.stopAnimating()

                        if job.blueprintImages.count == 0 {
                            self.renderInstruction("Import a blueprint for this job.")
                            self.showDropbox()
                        }
                    },
                    onError: { error, statusCode, responseString in
                        self.blueprintsPageViewController?.resetViewControllers()
                        self.reloadingJob = false
                    }
                )
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier! == "BlueprintsPageViewControllerEmbedSegue" {
            blueprintsPageViewController = segue.destinationViewController as! BlueprintsPageViewController
            blueprintsPageViewController.blueprintsPageViewControllerDelegate = self
        }
    }

    private func showDropbox() {
        for importFromDropboxButton in [importFromDropboxIconButton, importFromDropboxTextButton] {
            if let importFromDropboxButton = importFromDropboxButton {
                importFromDropboxButton.superview!.bringSubviewToFront(importFromDropboxButton)
                importFromDropboxButton.alpha = 1.0
            }
        }
    }

    private func hideDropbox() {
        for importFromDropboxButton in [importFromDropboxIconButton, importFromDropboxTextButton] {
            if let importFromDropboxButton = importFromDropboxButton {
                importFromDropboxButton.alpha = 0.0
            }
        }
    }

    func importFromDropbox(sender: UIButton) {
        renderInstruction(nil)

        DBChooser.defaultChooser().openChooserForLinkType(DBChooserLinkTypeDirect, fromViewController: self) { [weak self] results in
            if let results = results {
                for result in results {
                    let sourceURL = (result as! DBChooserResult).link
                    let filename = (result as! DBChooserResult).name
                    if let fileExtension = sourceURL.pathExtension {
                        if fileExtension.lowercaseString == "pdf" {
                            self!.importFromSourceURL(sourceURL, filename: filename)
                        } else {
                            self!.showToast("Invalid file format specified; please choose a valid PDF document.", dismissAfter: 3.0)
                            self!.renderInstruction("Import a blueprint for this job.")
                            self!.showDropbox()

                        }
                    }
                }
            } else {
                self!.refresh()
            }
        }
    }

    private func importFromSourceURL(sourceURL: NSURL, filename: String) {
        if let job = job {
            let params: [String : AnyObject] = ["tags": ["blueprint"], "metadata": ["filename": filename]]
            ApiService.sharedService().addAttachmentFromSourceUrl(sourceURL, toJobWithId: String(job.id), params: params,
                onSuccess: { [weak self] statusCode, mappingResult in
                    self!.importedPdfAttachment = mappingResult.firstObject as! Attachment
                }, onError: { error, statusCode, responseString in

                }
            )
        }
    }

    private func renderInstruction(message: String!) {
        if let message = message {
            importInstructionsLabel?.text = message
            importInstructionsLabel?.alpha = 1.0

            importInstructionsContainerView?.superview?.bringSubviewToFront(importInstructionsContainerView)
            importInstructionsContainerView?.alpha = 1.0

            floorplansContainerView?.alpha = 0.0

            blueprintActivityIndicatorView?.stopAnimating()
            blueprintPreviewContainerView?.alpha = 0.0
        } else if job.blueprintImageUrl != nil {
            blueprintActivityIndicatorView?.stopAnimating()
            blueprintPreviewContainerView?.alpha = 0.0
        } else {
            importInstructionsLabel?.text = ""
            importInstructionsLabel?.alpha = 0.0

            importInstructionsContainerView?.alpha = 0.0
            importInstructionsContainerView?.superview?.sendSubviewToBack(importInstructionsContainerView)

            blueprintActivityIndicatorView?.startAnimating()
            blueprintPreviewContainerView?.alpha = 1.0
        }
    }

    func setBlueprintImage(image: UIImage) {
        blueprintPreviewImageView.image = image
        blueprintPreviewImageView.alpha = 1.0

        blueprintPreviewStatusLabel?.alpha = 0.0
        blueprintPreviewStatusLabel?.text = ""

        blueprintActivityIndicatorView.stopAnimating()
        hideDropbox()

        reloadingBlueprint = false
    }

    // MARK: BlueprintsPageViewControllerDelegate

    func navigationItemForBlueprintsPageViewController(viewController: BlueprintsPageViewController) -> UINavigationItem! {
        return navigationItem
    }

    func jobForBlueprintsPageViewController(viewController: BlueprintsPageViewController) -> Job! {
        return job
    }

    func blueprintsForBlueprintsPageViewController(viewController: BlueprintsPageViewController) -> [Attachment] {
        var blueprints = [Attachment]()
        if let job = job {
            blueprints = job.blueprintImages
        }
        return blueprints
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
