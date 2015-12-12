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

class JobBlueprintsViewController: ViewController {

    var delegate: JobBlueprintsViewControllerDelegate!

    @IBOutlet private weak var importFromDropboxIconButton: UIButton!
    @IBOutlet private weak var importFromDropboxTextButton: UIButton!

    private var job: Job! {
        if let job = delegate?.jobForJobBlueprintsViewController(self) {
            return job
        }
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Setup Blueprint"

        for importFromDropboxButton in [importFromDropboxIconButton, importFromDropboxTextButton] {
            importFromDropboxButton.addTarget(self, action: "importFromDropbox:", forControlEvents: .TouchUpInside)
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
}
