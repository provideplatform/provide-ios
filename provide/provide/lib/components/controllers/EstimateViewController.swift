//
//  EstimateViewController.swift
//  provide
//
//  Created by Kyle Thomas on 2/2/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class EstimateViewController: ViewController, BlueprintViewControllerDelegate {

    var estimate: Estimate! {
        didSet {
            if let estimate = estimate {
                navigationItem.title = "\(estimate.id)"

                reload()
            }
        }
    }

    @IBOutlet private weak var editBarButtonItem: UIBarButtonItem!

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var amountLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let _ = estimate {
            reload()
        }

        activityIndicatorView?.startAnimating()

        NSNotificationCenter.defaultCenter().addObserverForName("AttachmentChanged") { notification in
            if let userInfo = notification.object {
                let attachmentId = userInfo["attachment_id"] as? Int
                let attachableType = userInfo["attachable_type"] as? String
                let attachableId = userInfo["attachable_id"] as? Int

                if attachmentId != nil && attachableType != nil && attachableId != nil {
                    if attachableType == "estimate" {
                        if self.estimate.id == attachableId {
                            self.estimate.reload([:],
                                onSuccess: { statusCode, mappingResult in
                                    self.reload()
                                },
                                onError: { error, statusCode, responseString in

                                }
                            )
                        }
                    }
                }
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: self)

        if segue.identifier! == "BlueprintViewControllerSegue" {
            (segue.destinationViewController as! BlueprintViewController).blueprintViewControllerDelegate = self
        }
    }

    func hideLabels() {

    }

    private func reload() {
        activityIndicatorView?.startAnimating()

        if let createdAt = estimate.createdAt {
            dateLabel?.text = "\(createdAt.monthName) \(createdAt.dayOfMonth), \(createdAt.year)"
        } else {
            dateLabel?.text = ""
        }

        if let amount = estimate.amount {
            amountLabel?.text = "$\(amount)"
        } else if let humanReadableTotalSqFt = estimate.humanReadableTotalSqFt {
            amountLabel?.text = humanReadableTotalSqFt
        } else {
            amountLabel?.text = ""
        }

        if estimate.jobId > 0 {
            if estimate.attachments.count > 0 {
                let attachment = estimate.attachments.first!
                imageView?.contentMode = .ScaleAspectFit
                imageView?.sd_setImageWithURL(attachment.url, placeholderImage: nil, completed: { (image, error, cacheType, url) -> Void in
                    self.imageView?.alpha = 1.0
                    self.activityIndicatorView?.stopAnimating()
                })
            } else {
                imageView?.alpha = 0.0
                imageView?.image = nil
                activityIndicatorView?.stopAnimating()
            }
        } else {
            imageView?.alpha = 0.0
            imageView?.image = nil
            activityIndicatorView?.stopAnimating()
        }
    }

    // BlueprintViewControllerDelegate

    func jobForBlueprintViewController(viewController: BlueprintViewController) -> Job! {
        return nil
    }

    func estimateForBlueprintViewController(viewController: BlueprintViewController) -> Estimate! {
        return estimate
    }

    func blueprintImageForBlueprintViewController(viewController: BlueprintViewController) -> UIImage! {
        return imageView.image
    }

    func scaleCanBeSetByBlueprintViewController(viewController: BlueprintViewController) -> Bool {
        return false
    }

    func newWorkOrderCanBeCreatedByBlueprintViewController(viewController: BlueprintViewController) -> Bool {
        return false
    }

    func areaSelectorIsAvailableForBlueprintViewController(viewController: BlueprintViewController) -> Bool {
        return true
    }

//    optional func scaleCanBeSetByBlueprintViewController(viewController: BlueprintViewController) -> Bool
//    optional func scaleWasSetForBlueprintViewController(viewController: BlueprintViewController)
//    optional func newWorkOrderCanBeCreatedByBlueprintViewController(viewController: BlueprintViewController) -> Bool
//    optional func navigationControllerForBlueprintViewController(viewController: BlueprintViewController) -> UINavigationController!

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
