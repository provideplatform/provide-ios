//
//  JobFloorplansViewController.swift
//  provide
//
//  Created by Kyle Thomas on 12/9/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

class JobFloorplansViewController: ViewController,
                                   FloorplansPageViewControllerDelegate {

    fileprivate var floorplanPreviewBackgroundColor = UIColor(red: 0.11, green: 0.29, blue: 0.565, alpha: 0.45)

    @IBOutlet fileprivate weak var floorplanPreviewContainerView: UIView! {
        didSet {
            if let floorplanPreviewContainerView = floorplanPreviewContainerView {
                floorplanPreviewContainerView.backgroundColor = floorplanPreviewBackgroundColor
            }
        }
    }
    @IBOutlet fileprivate weak var floorplanActivityIndicatorView: UIActivityIndicatorView!
    @IBOutlet fileprivate weak var floorplanPreviewStatusLabel: UILabel! {
        didSet {
            if let floorplanPreviewStatusLabel = floorplanPreviewStatusLabel {
                floorplanPreviewStatusLabel.text = ""
                floorplanPreviewStatusLabel.alpha = 0.0
            }
        }
    }

    @IBOutlet fileprivate weak var floorplanPreviewImageView: UIImageView!

    @IBOutlet fileprivate weak var floorplanPagesContainerView: UIView!
    @IBOutlet fileprivate weak var estimatesContainerView: UIView!
    @IBOutlet fileprivate weak var floorplansContainerView: UIView!

    @IBOutlet fileprivate weak var importInstructionsContainerView: UIView!
    @IBOutlet fileprivate weak var importInstructionsLabel: UILabel!

    @IBOutlet fileprivate weak var importFromDropboxIconButton: UIButton!
    @IBOutlet fileprivate weak var importFromDropboxTextButton: UIButton!

    fileprivate weak var floorplansPageViewController: FloorplansPageViewController!
    fileprivate weak var floorplanViewController: FloorplanViewController!

    fileprivate var reloadingFloorplan = false
    fileprivate var reloadingJob = false
    fileprivate var importedPdfAttachment: Attachment! {
        didSet {
            if let _ = importedPdfAttachment {
                hideDropbox()
                importStatus = "Importing your floorplan..."
            }
        }
    }
    fileprivate var importedPngAttachment: Attachment! {
        didSet {
            if let _ = importedPngAttachment {
                importStatus = "Generating high-fidelity representation (this may take up to a few minutes)"
            }
        }
    }
    fileprivate var importStatus: String! {
        didSet {
            if let importStatus = importStatus {
                view.sendSubview(toBack: importInstructionsContainerView)
                importInstructionsContainerView.alpha = 0.0

                floorplanActivityIndicatorView.startAnimating()
                floorplanPreviewStatusLabel?.text = importStatus
                floorplanPreviewStatusLabel?.alpha = 1.0
                floorplanPreviewContainerView?.bringSubview(toFront: floorplanPreviewStatusLabel)
                floorplanPreviewContainerView?.alpha = 1.0
            } else {
                floorplanPreviewStatusLabel?.text = ""
            }
        }
    }

    var job: Job! {
        didSet {
            if let _ = job {
                if isViewLoaded {
                    refresh()
                }
            }
        }
    }

    fileprivate var floorplanImportTimer: Timer!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        //tabBarItem.image = FAKFontAwesome.photoIconWithSize(25.0).imageWithSize(CGSize(width: 25.0, height: 25.0))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = ""

        importInstructionsLabel?.text = ""
        importInstructionsContainerView?.alpha = 0.0
        importInstructionsContainerView?.superview?.bringSubview(toFront: importInstructionsContainerView)

        estimatesContainerView?.alpha = 0.0
        estimatesContainerView?.superview?.bringSubview(toFront: estimatesContainerView)

        floorplansContainerView?.alpha = 0.0
        floorplansContainerView?.superview?.bringSubview(toFront: floorplansContainerView)

        floorplanPreviewImageView?.alpha = 0.0
        floorplanPreviewImageView?.contentMode = .scaleAspectFit

        for importFromDropboxButton in [importFromDropboxIconButton, importFromDropboxTextButton] {
            importFromDropboxButton?.addTarget(self, action: #selector(JobFloorplansViewController.importFromDropbox(_:)), for: .touchUpInside)
        }

        hideDropbox()

        if job != nil {
            refresh()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        teardownFloorplanViewController()
    }

    func teardown() -> UIImage? {
        floorplanPreviewImageView?.image = nil
        return teardownFloorplanViewController()
    }

    @discardableResult
    func teardownFloorplanViewController() -> UIImage? {
        return floorplanViewController?.teardown()
    }

    func refresh() {
        if !reloadingJob {
            if let job = job {
                reloadingJob = true

                job.reload(
                    { statusCode, mappingResult in
                        self.floorplansPageViewController?.resetViewControllers()
                        self.reloadingJob = false

                        self.floorplanPagesContainerView?.alpha = 1.0
                        self.floorplanActivityIndicatorView?.stopAnimating()

                        if job.floorplans.count == 0 {
                            self.renderInstruction("Import a floorplan for this job.")
                            self.showDropbox()
                        } else {
                            if self.floorplansPageViewController == nil {
                                self.floorplanActivityIndicatorView?.startAnimating()
                            }
                        }
                    },
                    onError: { error, statusCode, responseString in
                        self.floorplansPageViewController?.resetViewControllers()
                        self.reloadingJob = false
                    }
                )
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier! == "FloorplansPageViewControllerEmbedSegue" {
            floorplansPageViewController = segue.destination as! FloorplansPageViewController
            floorplansPageViewController.floorplansPageViewControllerDelegate = self

            dispatch_after_delay(0.0) {
                self.floorplanActivityIndicatorView?.stopAnimating()
            }
        }
    }

    fileprivate func showDropbox() {
        for importFromDropboxButton in [importFromDropboxIconButton, importFromDropboxTextButton] {
            if let importFromDropboxButton = importFromDropboxButton {
                importFromDropboxButton.superview!.bringSubview(toFront: importFromDropboxButton)
                importFromDropboxButton.alpha = 1.0
            }
        }
    }

    fileprivate func hideDropbox() {
        for importFromDropboxButton in [importFromDropboxIconButton, importFromDropboxTextButton] {
            if let importFromDropboxButton = importFromDropboxButton {
                importFromDropboxButton.alpha = 0.0
            }
        }
    }

    func importFromDropbox(_ sender: UIButton) {
        renderInstruction(nil)

        DBChooser.default().open(for: DBChooserLinkTypeDirect, from: self) { results in
            if let results = results {
                for result in results {
                    let sourceURL = (result as! DBChooserResult).link
                    let filename = (result as! DBChooserResult).name
                    if let fileExtension = sourceURL?.pathExtension {
                        if fileExtension.lowercased() == "pdf" {
                            self.importFromSourceURL(sourceURL!, filename: filename!)
                        } else {
                            self.showToast("Invalid file format specified; please choose a valid PDF document.", dismissAfter: 3.0)
                            self.renderInstruction("Import a floorplan for this job.")
                            self.showDropbox()

                        }
                    }
                }
            } else {
                self.refresh()
            }
        }

        if isSimulator() {
            dispatch_after_delay(1.0) {
                let sourceURL = URL(string: "https://provide-production.s3.amazonaws.com/4e00588c-d532-42ef-a86b-a543072aab1c.pdf")
                self.showToast("Importing PDF document at source url \(sourceURL?.absoluteString).", dismissAfter: 1.0)
                dispatch_after_delay(1.2) {
                    self.importFromSourceURL(sourceURL!, filename: "concept facility 1st floor.pdf")
                }
            }
        }
    }

    fileprivate func importFromSourceURL(_ sourceURL: URL, filename: String) {
        if let job = job {
            let floorplan = Floorplan()
            floorplan.jobId = job.id
            floorplan.name = filename
            floorplan.pdfUrlString = sourceURL.absoluteString

            floorplan.save(
                { statusCode, mappingResult in
                    self.job.reloadFloorplans(
                        { statusCode, mappingResult in
                            let fp = mappingResult?.firstObject as! Floorplan
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

    fileprivate func renderInstruction(_ message: String!) {
        if let message = message {
            importInstructionsLabel?.text = message
            importInstructionsLabel?.alpha = 1.0

            importInstructionsContainerView?.superview?.bringSubview(toFront: importInstructionsContainerView)
            importInstructionsContainerView?.alpha = 1.0

            floorplansContainerView?.alpha = 0.0

            floorplanActivityIndicatorView?.stopAnimating()
            floorplanPreviewContainerView?.alpha = 0.0
        } else if job.floorplans.count > 0 {
            floorplanActivityIndicatorView?.stopAnimating()
            floorplanPreviewContainerView?.alpha = 0.0
        } else {
            importInstructionsLabel?.text = ""
            importInstructionsLabel?.alpha = 0.0

            importInstructionsContainerView?.alpha = 0.0
            importInstructionsContainerView?.superview?.sendSubview(toBack: importInstructionsContainerView)

            floorplanActivityIndicatorView?.startAnimating()
            floorplanPreviewContainerView?.alpha = 1.0
        }
    }

    func setFloorplanImage(_ image: UIImage) {
        floorplanPreviewImageView.image = image
        floorplanPreviewImageView.alpha = 1.0

        floorplanPreviewStatusLabel?.alpha = 0.0
        floorplanPreviewStatusLabel?.text = ""

        floorplanActivityIndicatorView.stopAnimating()
        hideDropbox()

        reloadingFloorplan = false
    }

    // MARK: FloorplansPageViewControllerDelegate

    func navigationItemForFloorplansPageViewController(_ viewController: FloorplansPageViewController) -> UINavigationItem! {
        return navigationItem
    }

    func jobForFloorplansPageViewController(_ viewController: FloorplansPageViewController) -> Job! {
        return job
    }

    func floorplansForFloorplansPageViewController(_ viewController: FloorplansPageViewController) -> Set<Floorplan> {
        var floorplans = Set<Floorplan>()
        if let job = job {
            for floorplan in job.floorplans {
                floorplans.insert(floorplan)
            }
        }
        return floorplans
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
