//
//  ProviderEnRouteViewController.swift
//  provide
//
//  Created by Kyle Thomas on 9/3/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import KTSwiftExtensions

class ProviderEnRouteViewController: ViewController {

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var categoryLabel: UILabel!
    @IBOutlet private weak var makeLabel: UILabel!
    @IBOutlet private weak var modelLabel: UILabel!
    @IBOutlet private weak var profileImageView: UIImageView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    fileprivate var workOrder: WorkOrder! {
        didSet {
            if workOrder == nil {
                if oldValue != nil {
                    UIView.animate(
                        withDuration: 0.25,
                        animations: { [weak self] in
                            self!.view.frame.origin.y += self!.view.frame.height
                        },
                        completion: { [weak self] completed in
                            if self!.workOrder == nil {
                                self!.activityIndicatorView.startAnimating()
                                self!.nameLabel.isHidden = true
                                self!.categoryLabel.isHidden = true
                                self!.makeLabel.isHidden = true
                                self!.modelLabel.isHidden = true
                                self!.profileImageView.isHidden = true
                            }
                        }
                    )
                }
            } else {
                self.nameLabel.text = workOrder.providers.first!.firstName!.uppercased()
                self.nameLabel.isHidden = false

                self.categoryLabel.text = ""  // FIXME -- workOrder.category.desc
                self.categoryLabel.isHidden = false

                self.makeLabel.text = ""
                self.makeLabel.isHidden = false

                self.modelLabel.text = ""
                self.modelLabel.isHidden = false

                view.bringSubview(toFront: activityIndicatorView)
                activityIndicatorView.startAnimating()

                if let profileImageUrl = workOrder.providerProfileImageUrl {
                    profileImageView.contentMode = .scaleAspectFit
                    profileImageView.sd_setImage(with: profileImageUrl) { [weak self] image, error, imageCacheType, url in
                        self?.activityIndicatorView.stopAnimating()

                        self?.view.bringSubview(toFront: self!.profileImageView)
                        self?.profileImageView.makeCircular()
                        self?.profileImageView.alpha = 1.0
                    }
                } else {
                    activityIndicatorView.stopAnimating()

                    profileImageView.image = nil  // TODO: render default profile pic
                    profileImageView.alpha = 0.0
                }

                if oldValue == nil {
                    UIView.animate(
                        withDuration: 0.25,
                        animations: { [weak self] in
                            self!.view.frame.origin.y -= self!.view.frame.height
                        },
                        completion: { [weak self] _ in
                            logInfo("Presented provider en route for work order: \(self!.workOrder!)")
                        }
                    )
                }
            }
        }
    }

    func prepareForReuse() {
        workOrder = nil
    }

    func setWorkOrder(_ workOrder: WorkOrder) {
        self.workOrder = workOrder
    }
}
