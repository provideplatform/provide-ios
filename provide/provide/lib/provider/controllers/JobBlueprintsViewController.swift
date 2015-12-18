//
//  JobBlueprintsViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol JobBlueprintsViewControllerDelegate {
    func jobForJobBlueprintsViewController(viewController: JobBlueprintsViewController) -> Job!
}

class JobBlueprintsViewController: ViewController, BlueprintViewControllerDelegate {

    private var blueprintPreviewBackgroundColor = UIColor(red: 0.11, green: 0.29, blue: 0.565, alpha: 0.45)

    var delegate: JobBlueprintsViewControllerDelegate! {
        didSet {
            if let _ = delegate {
                if let _ = job {
                    if shouldLoadBlueprint {
                        importInstructionsContainerView?.alpha = 0.0
                        loadBlueprint()
                        blueprintViewController?.blueprintViewControllerDelegate = self
                    } else {
                        importInstructionsContainerView?.alpha = 1.0
                        importInstructionsLabel?.text = "Congrats! Your blueprint is configured properly."
                        importInstructionsLabel?.alpha = 1.0

                        blueprintActivityIndicatorView?.stopAnimating()
                        blueprintPreviewContainerView?.alpha = 0.0
                    }
                }
            }
        }
    }

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

    @IBOutlet private weak var importInstructionsContainerView: UIView!
    @IBOutlet private weak var importInstructionsLabel: UILabel!

    @IBOutlet private weak var importFromDropboxIconButton: UIButton!
    @IBOutlet private weak var importFromDropboxTextButton: UIButton!

    private var blueprintViewController: BlueprintViewController!

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
                blueprintActivityIndicatorView.startAnimating()
                blueprintPreviewStatusLabel.text = importStatus
                blueprintPreviewStatusLabel.alpha = 1.0
                blueprintPreviewContainerView.bringSubviewToFront(blueprintPreviewStatusLabel)
                blueprintPreviewContainerView.alpha = 1.0
            } else {
                blueprintPreviewStatusLabel.text = ""
            }
        }
    }

    private var job: Job! {
        if let job = delegate?.jobForJobBlueprintsViewController(self) {
            return job
        }
        return nil
    }

    private var shouldLoadBlueprint: Bool {
        var loadBlueprint = true
        if let blueprint = job?.blueprint {
            if let _ = blueprint.metadata["scale"] as? Double {
                loadBlueprint = false
            }
        }
        return loadBlueprint
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Setup Blueprint"

        importInstructionsLabel?.text = ""
        importInstructionsContainerView?.alpha = 0.0

        blueprintPreviewImageView?.alpha = 0.0

        for importFromDropboxButton in [importFromDropboxIconButton, importFromDropboxTextButton] {
            importFromDropboxButton.addTarget(self, action: "importFromDropbox:", forControlEvents: .TouchUpInside)
        }

        hideDropbox()

        NSNotificationCenter.defaultCenter().addObserverForName("AttachmentChanged") { notification in
            if let userInfo = notification.object {
                let attachmentId = userInfo["attachment_id"] as? Int
                let attachableType = userInfo["attachable_type"] as? String
                let attachableId = userInfo["attachable_id"] as? Int

                if attachmentId != nil && attachableType != nil && attachableId != nil {
                    if let job = self.job {
                        if attachableType == "job" && attachableId == job.id {
                            if let importedPdfAttachment = self.importedPdfAttachment {
                                if importedPdfAttachment.id == attachmentId {
                                    self.importStatus = "Processing your imported blueprint..."
                                } else if self.importedPngAttachment == nil {
                                    self.importedPngAttachment = Attachment()
                                    self.importedPngAttachment.id = attachmentId!
                                } else if self.importedPngAttachment.id == attachmentId {
                                    self.reloadJob()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier! == "BlueprintViewControllerEmbedSegue" {
            blueprintViewController = segue.destinationViewController as! BlueprintViewController
            blueprintViewController.blueprintViewControllerDelegate = self
        }
    }

    private func showDropbox() {
        for importFromDropboxButton in [importFromDropboxIconButton, importFromDropboxTextButton] {
            importFromDropboxButton.alpha = 1.0
        }
    }

    private func hideDropbox() {
        for importFromDropboxButton in [importFromDropboxIconButton, importFromDropboxTextButton] {
            importFromDropboxButton.alpha = 0.0
        }
    }

    func importFromDropbox(sender: UIButton) {
        DBChooser.defaultChooser().openChooserForLinkType(DBChooserLinkTypeDirect, fromViewController: self) { results in
            if let results = results {
                for result in results {
                    let sourceURL = (result as! DBChooserResult).link
                    self.importFromSourceURL(sourceURL)
                }
            }
        }
    }

    private func importFromSourceURL(sourceURL: NSURL) {
        if let job = job {
            let params: [String : AnyObject] = ["tags": ["blueprint"]]
            ApiService.sharedService().addAttachmentFromSourceUrl(sourceURL, toJobWithId: String(job.id), params: params,
                onSuccess: { statusCode, mappingResult in
                    self.importedPdfAttachment = mappingResult.firstObject as! Attachment
                }, onError: { error, statusCode, responseString in

                }
            )
        }
    }

    private func reloadJob() {
        if !reloadingJob {
            if let job = job {
                reloadingJob = true

                job.reload(
                    onSuccess: { statusCode, mappingResult in
                        self.loadBlueprint()
                        self.reloadingJob = false
                    },
                    onError: { error, statusCode, responseString in
                        self.loadBlueprint()
                        self.reloadingJob = false
                    }
                )
            }
        }
    }

    private func loadBlueprint(force: Bool = false) {
        if !reloadingBlueprint {
            if let blueprintImageUrl = job.blueprintImageUrl {
                reloadingBlueprint = true
                importStatus = nil

                blueprintActivityIndicatorView.startAnimating()
                blueprintPreviewContainerView.alpha = 1.0
                blueprintPreviewImageView.contentMode = .ScaleAspectFit
                blueprintPreviewImageView?.sd_setImageWithURL(blueprintImageUrl, placeholderImage: nil,
                    completed: { [weak self] image, error, cacheType, url in
                        self!.blueprintPreviewImageView.alpha = 1.0
                        self!.blueprintPreviewStatusLabel.alpha = 0.0
                        self!.blueprintPreviewStatusLabel.text = ""
                        self!.blueprintActivityIndicatorView.stopAnimating()
                        self!.hideDropbox()
                        self!.blueprintViewController.blueprintViewControllerDelegate = self!
                        self!.reloadingBlueprint = false
                    }
                )
            } else if importedPdfAttachment == nil {
                blueprintPreviewContainerView.alpha = 0.0
                blueprintActivityIndicatorView.stopAnimating()
                showDropbox()
                importInstructionsContainerView?.alpha = 1.0
                reloadingBlueprint = false
            }
        }
    }

    // MARK: BlueprintViewControllerDelegate

    func jobForBlueprintViewController(viewController: BlueprintViewController) -> Job! {
        return job
    }

    func newWorkOrderCanBeCreatedByBlueprintViewController(viewController: BlueprintViewController) -> Bool {
        return false
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
