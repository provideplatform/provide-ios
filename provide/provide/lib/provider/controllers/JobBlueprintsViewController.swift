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
                    loadBlueprint()
                    blueprintViewController?.blueprintViewControllerDelegate = self
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
    @IBOutlet private weak var blueprintPreviewImageView: UIImageView!

    @IBOutlet private weak var importFromDropboxIconButton: UIButton!
    @IBOutlet private weak var importFromDropboxTextButton: UIButton!

    private var blueprintViewController: BlueprintViewController!

    private var job: Job! {
        if let job = delegate?.jobForJobBlueprintsViewController(self) {
            return job
        }
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Setup Blueprint"

        blueprintPreviewImageView?.alpha = 0.0

        for importFromDropboxButton in [importFromDropboxIconButton, importFromDropboxTextButton] {
            importFromDropboxButton.addTarget(self, action: "importFromDropbox:", forControlEvents: .TouchUpInside)
        }

        hideDropbox()
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
                    let attachment = mappingResult.firstObject as! Attachment
                    print("created attachment \(attachment)")
                }, onError: { error, statusCode, responseString in

                }
            )
        }
    }

    private func loadBlueprint() {
        if let blueprintImageUrl = job.blueprintImageUrl {
            blueprintActivityIndicatorView.startAnimating()
            blueprintPreviewContainerView.alpha = 1.0
            blueprintPreviewImageView.contentMode = .ScaleAspectFit
            blueprintPreviewImageView?.sd_setImageWithURL(blueprintImageUrl, placeholderImage: nil,
                completed: { image, error, cacheType, url in
                    self.blueprintPreviewImageView.alpha = 1.0
                    self.blueprintActivityIndicatorView.stopAnimating()
                    self.hideDropbox()
                }
            )
        } else {
            blueprintPreviewContainerView.alpha = 0.0
            blueprintActivityIndicatorView.stopAnimating()
            showDropbox()
        }
    }

    // MARK: BlueprintViewControllerDelegate

    func jobForBlueprintViewController(viewController: BlueprintViewController) -> Job! {
        return job
    }

    func newWorkOrderCanBeCreatedByBlueprintViewController(viewController: BlueprintViewController) -> Bool {
        return false
    }
}
