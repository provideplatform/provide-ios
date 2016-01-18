//
//  JobBlueprintsViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol JobBlueprintsViewControllerDelegate: NSObjectProtocol {
    func jobForJobBlueprintsViewController(viewController: JobBlueprintsViewController) -> Job!
    func jobBlueprintsViewController(viewController: JobBlueprintsViewController, didSetScaleForBlueprintViewController blueprintViewController: BlueprintViewController)
}

class JobBlueprintsViewController: ViewController,
                                   BlueprintViewControllerDelegate,
                                   FloorplansViewControllerDelegate {

    private var blueprintPreviewBackgroundColor = UIColor(red: 0.11, green: 0.29, blue: 0.565, alpha: 0.45)

    weak var delegate: JobBlueprintsViewControllerDelegate! {
        didSet {
            if let _ = delegate {
                if let _ = job {
                    refresh()
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

    @IBOutlet private weak var floorplansContainerView: UIView!

    @IBOutlet private weak var importInstructionsContainerView: UIView!
    @IBOutlet private weak var importInstructionsLabel: UILabel!

    @IBOutlet private weak var importFromDropboxIconButton: UIButton!
    @IBOutlet private weak var importFromDropboxTextButton: UIButton!

    private weak var blueprintViewController: BlueprintViewController!
    private weak var floorplansViewController: FloorplansViewController!

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

    private var hasBlueprintScale: Bool {
        if let blueprint = job?.blueprint {
            if let _ = blueprint.metadata["scale"] as? Double {
                return true
            }
        }
        return false
    }

    private var shouldLoadBlueprint: Bool {
        if let job = job {
            if job.blueprintImageUrl == nil {
                return false
            }
            return !hasBlueprintScale || job.isResidential
        }
        return false
    }

    private var viewLoaded = false

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "SETUP BLUEPRINT"

        importInstructionsLabel?.text = ""
        importInstructionsContainerView?.alpha = 0.0
        importInstructionsContainerView?.superview?.bringSubviewToFront(importInstructionsContainerView)

        floorplansContainerView?.alpha = 0.0
        floorplansContainerView?.superview?.bringSubviewToFront(floorplansContainerView)

        blueprintPreviewImageView?.alpha = 0.0
        blueprintPreviewImageView?.contentMode = .ScaleAspectFit

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
                            } else {
                                self.refresh()
                            }
                        }
                    }
                }
            }
        }

        if job != nil && delegate != nil {
            refresh()
        }

        viewLoaded = true
    }

    func teardown() -> UIImage? {
        blueprintPreviewImageView?.image = nil
        return teardownBlueprintViewController()
    }

    func teardownBlueprintViewController() -> UIImage? {
        return blueprintViewController?.teardown()
    }

    func refresh() {
//        if job.isCommercial {
//            navigationItem.title = "SETUP BLUEPRINT"
//        } else if job.isResidential {
//            navigationItem.title = "SETUP FLOORPLAN"
//        }
        if let job = job {
            if job.isCommercial {
                if let _ = floorplansContainerView.superview {
                    floorplansContainerView.removeFromSuperview()
                }
            }
        }

        if shouldLoadBlueprint {
            importInstructionsContainerView?.alpha = 0.0
            loadBlueprint()
            blueprintViewController?.blueprintViewControllerDelegate = self
        } else if let job = job {
            if job.hasPendingBlueprint {
                importStatus = "Generating high-fidelity blueprint representation (this may take up to a few minutes)"
            } else if job.isCommercial {
                if job.blueprintImageUrl == nil && importedPdfAttachment == nil {
                    if job.blueprintImageUrl == nil && importedPngAttachment == nil {
                        job.reload(
                            onSuccess: { [weak self] statusCode, mappingResult in
                                if job.blueprintImageUrl == nil && job.blueprints.count == 0 {
                                    self?.renderInstruction("Import a blueprint for this job.")
                                    self?.showDropbox()
                                } else if job.hasPendingBlueprint {
                                    self?.importStatus = "Generating high-fidelity blueprint representation (this may take up to a few minutes)"
                                }
                            },
                            onError: { error, statusCode, responseString in

                            }
                        )
                    }
                } else if job.blueprintImageUrl != nil {
                    renderInstruction("Congrats! Your blueprint is configured properly.")
                }
            } else if job.isResidential {
                if job.blueprintImageUrl == nil {
                    renderFloorplans()
                }
            }
        } else {
            renderInstruction("Loading job")
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)

        if segue.identifier! == "BlueprintViewControllerEmbedSegue" {
            blueprintViewController = segue.destinationViewController as! BlueprintViewController
            //blueprintViewController.blueprintViewControllerDelegate = self
        } else if segue.identifier! == "FloorplansViewControllerEmbedSegue" {
            floorplansViewController = segue.destinationViewController as! FloorplansViewController
            floorplansViewController.delegate = self
        }
    }

    private func showDropbox() {
        for importFromDropboxButton in [importFromDropboxIconButton, importFromDropboxTextButton] {
            importFromDropboxButton.superview!.bringSubviewToFront(importFromDropboxButton)
            importFromDropboxButton.alpha = 1.0
        }
    }

    private func hideDropbox() {
        for importFromDropboxButton in [importFromDropboxIconButton, importFromDropboxTextButton] {
            importFromDropboxButton.alpha = 0.0
        }
    }

    func importFromDropbox(sender: UIButton) {
        renderInstruction(nil)

        DBChooser.defaultChooser().openChooserForLinkType(DBChooserLinkTypeDirect, fromViewController: self) { [weak self] results in
            if let results = results {
                for result in results {
                    let sourceURL = (result as! DBChooserResult).link
                    self!.importFromSourceURL(sourceURL)
                }
            } else {
                self!.refresh()
            }
        }
    }

    private func importFromSourceURL(sourceURL: NSURL) {
        if let job = job {
            let params: [String : AnyObject] = ["tags": ["blueprint"]]
            ApiService.sharedService().addAttachmentFromSourceUrl(sourceURL, toJobWithId: String(job.id), params: params,
                onSuccess: { [weak self] statusCode, mappingResult in
                    self!.importedPdfAttachment = mappingResult.firstObject as! Attachment
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
                    onSuccess: { [weak self] statusCode, mappingResult in
                        self!.loadBlueprint()
                        self!.reloadingJob = false
                    },
                    onError: { [weak self] error, statusCode, responseString in
                        self!.loadBlueprint()
                        self!.reloadingJob = false
                    }
                )
            }
        }
    }

    private func renderFloorplans() {
        renderInstruction(nil)

        floorplansViewController.reset()

        floorplansContainerView?.alpha = 1.0
        floorplansContainerView?.superview?.bringSubviewToFront(floorplansContainerView)
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

    private func loadBlueprint(force: Bool = false) {
        if !reloadingBlueprint {
            if let image = blueprintImageForBlueprintViewController(blueprintViewController) {
                setBlueprintImage(image)
            } else if let blueprintImageUrl = job.blueprintImageUrl {
                reloadingBlueprint = true
                importStatus = nil

                blueprintActivityIndicatorView.startAnimating()
                blueprintPreviewContainerView.alpha = 1.0

                ApiService.sharedService().fetchImage(blueprintImageUrl,
                    onImageFetched: { statusCode, image  in
                        self.setBlueprintImage(image)
                    },
                    onError: { error, statusCode, responseString in
                        
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

    func setBlueprintImage(image: UIImage) {
        blueprintPreviewImageView.image = image
        blueprintPreviewImageView.alpha = 1.0

        blueprintPreviewStatusLabel.alpha = 0.0
        blueprintPreviewStatusLabel.text = ""

        blueprintActivityIndicatorView.stopAnimating()
        hideDropbox()

        blueprintViewController!.blueprintViewControllerDelegate = self
        reloadingBlueprint = false
    }

    // MARK: BlueprintViewControllerDelegate

    func jobForBlueprintViewController(viewController: BlueprintViewController) -> Job! {
        return job
    }

    func blueprintImageForBlueprintViewController(viewController: BlueprintViewController) -> UIImage! {
        if let image = blueprintPreviewImageView?.image {
            return image
        }
        return nil
    }

    func scaleWasSetForBlueprintViewController(viewController: BlueprintViewController) {
        delegate?.jobBlueprintsViewController(self, didSetScaleForBlueprintViewController: viewController)
    }

    func scaleCanBeSetByBlueprintViewController(viewController: BlueprintViewController) -> Bool {
        return shouldLoadBlueprint
    }

    func newWorkOrderCanBeCreatedByBlueprintViewController(viewController: BlueprintViewController) -> Bool {
        return false
    }

    // MARK: FloorplansViewControllerDelegate

    func customerIdForFloorplansViewController(viewController: FloorplansViewController) -> Int {
        if let job = job {
            return job.customerId
        }
        return 0
    }

    func floorplansViewController(viewController: FloorplansViewController, didSelectFloorplan floorplan: Floorplan) {
        floorplansContainerView.removeFromSuperview()

        importStatus = "Using floorplan \(floorplan.name)..."

        if job.floorplans == nil {
            job.floorplans = [Floorplan]()
        }

        job.floorplans.append(floorplan)

        job.save(
            onSuccess: { statusCode, mappingResult in
                self.job.reload(
                    onSuccess: { statusCode, mappingResult in
                        self.refresh()
                    },
                    onError: { error, statusCode, responseString in

                    }
                )
            },
            onError: { error, statusCode, responseString in

            }
        )
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
