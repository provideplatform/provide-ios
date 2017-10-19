//
//  ProviderEnRouteViewController.swift
//  provide
//
//  Created by Kyle Thomas on 9/3/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

class ProviderEnRouteViewController: ViewController {

    @IBOutlet private weak var providerStatusLabel: UILabel!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var categoryLabel: UILabel!
    @IBOutlet private weak var makeLabel: UILabel!
    @IBOutlet private weak var modelLabel: UILabel!
    @IBOutlet private weak var profileImageView: ProfileImageView!
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    private weak var workOrder: WorkOrder! {
        didSet {
            if workOrder == nil {
                CheckinService.shared.stop()
                LocationService.shared.disableNavigationAccuracy()
                if oldValue != nil {
                    LocationService.shared.background()
                }

                if oldValue != nil {
                    UIView.animate(withDuration: 0.25, animations: {
                        self.view.frame.origin.y += self.view.height
                    }, completion: { completed in
                        if self.workOrder == nil {
                            self.activityIndicatorView.startAnimating()
                            self.providerStatusLabel.isHidden = true
                            self.nameLabel.isHidden = true
                            self.categoryLabel.isHidden = true
                            self.makeLabel.isHidden = true
                            self.modelLabel.isHidden = true
                            self.profileImageView.isHidden = true
                        }
                    })
                }
            } else {
                LocationService.shared.start()
                LocationService.shared.enableNavigationAccuracy(disableIdleTimer: false)
                CheckinService.shared.start()
                CheckinService.shared.enableNavigationAccuracy()

                refreshStatus()

                nameLabel.text = workOrder.providers.last!.firstName!.uppercased()
                nameLabel.isHidden = false

                categoryLabel.text = ""  // FIXME -- workOrder.category.desc
                categoryLabel.isHidden = false

                makeLabel.text = ""
                makeLabel.isHidden = false

                modelLabel.text = ""
                modelLabel.isHidden = false

                refreshProvider()

                if oldValue == nil {
                    UIView.animate(withDuration: 0.25, animations: {
                        self.view.frame.origin.y -= self.view.height
                    }, completion: { completed in
                        logInfo("Presented provider en route for work order: \(self.workOrder!)")
                    })
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserverForName("WorkOrderChanged") { [weak self] notification in
            if let workOrder = notification.object as? WorkOrder, WorkOrderService.shared.inProgressWorkOrder?.id == workOrder.id {
                DispatchQueue.main.async {
                    self?.refreshStatus()
                }
            }
        }
    }

    private func refreshProvider() {
        if let workOrder = WorkOrderService.shared.inProgressWorkOrder {
            view.bringSubview(toFront: activityIndicatorView)
            activityIndicatorView.startAnimating()

            if let profileImageUrl = workOrder.providerProfileImageUrl {
                profileImageView.setImageWithUrl(profileImageUrl) { [weak self] in
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
        }
    }

    private func refreshStatus() {
        if let workOrder = WorkOrderService.shared.inProgressWorkOrder {
            if workOrder.status == nil {
                providerStatusLabel?.text = ""
                providerStatusLabel?.isHidden = false
                return
            }

            if workOrder.status == "en_route" {
                if workOrder.providerProfileImageUrl == nil {
                    workOrder.reload(onSuccess: { [weak self] _, _ in
                        self?.refreshProvider()
                    }, onError: { error, statusCode, response in
                        logWarn("Failed to reload work order")
                    })
                }
                providerStatusLabel?.text = "YOUR DRIVER IS EN ROUTE"
            } else if workOrder.status == "arriving" {
                providerStatusLabel?.text = "YOUR DRIVER IS ARRIVING NOW"
            } else if workOrder.status == "in_progress" {
                providerStatusLabel?.text = "HEADING TO DESTINATION"
            } else if workOrder.status == "completed" {
                providerStatusLabel?.text = "YOU HAVE ARRIVED"
            }
            providerStatusLabel?.isHidden = false
        }
    }

    func prepareForReuse() {
        workOrder = nil
    }

    func setWorkOrder(_ workOrder: WorkOrder) {
        self.workOrder = workOrder
    }
}
