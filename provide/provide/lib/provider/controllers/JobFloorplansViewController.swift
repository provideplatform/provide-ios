//
//  JobFloorplansViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/15.
//  Copyright © 2015 Provide Technologies Inc. All rights reserved.
//

import UIKit

class JobFloorplansViewController: ViewController,
                                   FloorplansPageViewControllerDelegate {

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

    private weak var blueprintsPageViewController: FloorplansPageViewController!
    private weak var floorplanViewController: FloorplanViewController!

    private var reloadingBlueprint = false
    private var reloadingJob = false
    private var importedPdfAttachment: Attachment! {
        didSet {
            if let _ = importedPdfAttachment {
                hideDropbox()
                importStatus = "Importing your floorplan..."
            }
        }
    }
    private var importedPngAttachment: Attachment! {
        didSet {
            if let _ = importedPngAttachment {
                importStatus = "Generating high-fidelity representation (this may take up to a few minutes)"
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
            importFromDropboxButton.addTarget(self, action: #selector(JobFloorplansViewController.importFromDropbox(_:)), forControlEvents: .TouchUpInside)
        }

        hideDropbox()

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
        return floorplanViewController?.teardown()
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

                        if job.floorplans.count == 0 {
                            self.renderInstruction("Import a floorplan for this job.")
                            self.showDropbox()
                        } else {
                            if self.blueprintsPageViewController == nil {
                                self.blueprintActivityIndicatorView?.startAnimating()
                            }
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

        if segue.identifier! == "FloorplansPageViewControllerEmbedSegue" {
            blueprintsPageViewController = segue.destinationViewController as! FloorplansPageViewController
            blueprintsPageViewController.floorplansPageViewControllerDelegate = self

            dispatch_after_delay(0.0) {
                self.blueprintActivityIndicatorView?.stopAnimating()
            }
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

        DBChooser.defaultChooser().openChooserForLinkType(DBChooserLinkTypeDirect, fromViewController: self) { results in
            if let results = results {
                for result in results {
                    let sourceURL = (result as! DBChooserResult).link
                    let filename = (result as! DBChooserResult).name
                    if let fileExtension = sourceURL.pathExtension {
                        if fileExtension.lowercaseString == "pdf" {
                            self.importFromSourceURL(sourceURL, filename: filename)
                        } else {
                            self.showToast("Invalid file format specified; please choose a valid PDF document.", dismissAfter: 3.0)
                            self.renderInstruction("Import a blueprint for this job.")
                            self.showDropbox()

                        }
                    }
                }
            } else {
                self.refresh()
            }
        }
    }

    private func importFromSourceURL(sourceURL: NSURL, filename: String) {
        if let job = job {
            let floorplan = Floorplan()
            floorplan.jobId = job.id
            floorplan.name = filename
            floorplan.pdfUrlString = sourceURL.absoluteString

            floorplan.save(
                onSuccess: { statusCode, mappingResult in
                    self.job.reloadFloorplans(
                        { statusCode, mappingResult in
                            let fp = mappingResult.firstObject as! Floorplan
                            self.importedPdfAttachment = fp.pdf
                        },
                        onError: { error, statusCode, responseString in

                        }
                    )
                },
                onError: { error, statusCode, responseString in

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
        } else if job.floorplans.count > 0 {
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

    // MARK: FloorplansPageViewControllerDelegate

    func navigationItemForBlueprintsPageViewController(viewController: FloorplansPageViewController) -> UINavigationItem! {
        return navigationItem
    }

    func jobForFloorplansPageViewController(viewController: FloorplansPageViewController) -> Job! {
        return job
    }

    func floorplansForFloorplansPageViewController(viewController: FloorplansPageViewController) -> Set<Floorplan> {
        var floorplans = Set<Floorplan>()
        if let job = job {
            for floorplan in job.floorplans {
                floorplans.insert(floorplan)
            }
        }
        return floorplans
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
