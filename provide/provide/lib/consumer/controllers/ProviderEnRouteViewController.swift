//
//  ProviderEnRouteViewController.swift
//  provide
//
//  Created by Kyle Thomas on 9/3/17.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

class ProviderEnRouteViewController: ViewController {

    func configure(workOrder: WorkOrder) {
        self.workOrder = workOrder
    }

    @IBOutlet private weak var providerStatusLabel: UILabel!
    @IBOutlet private weak var providerSubStatusLabel: UILabel!
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
            } else {
                LocationService.shared.start()
                LocationService.shared.enableNavigationAccuracy(disableIdleTimer: false)
                CheckinService.shared.start()
                CheckinService.shared.enableNavigationAccuracy()

                refreshStatus()

                configureUI()

                refreshProvider()
            }
        }
    }

    private func configureUI() {
        nameLabel?.text = workOrder?.providers.last?.firstName?.uppercased() ?? "Name Unknown"
        nameLabel?.isHidden = false

        categoryLabel?.text = workOrder?.category?.abbreviation ?? ""
        categoryLabel?.isHidden = false

        makeLabel?.text = ""
        makeLabel?.isHidden = false

        modelLabel?.text = ""
        modelLabel?.isHidden = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        KTNotificationCenter.addObserver(forName: .WorkOrderChanged, queue: .main) { [weak self] notification in
            if let workOrder = notification.object as? WorkOrder, WorkOrderService.shared.inProgressWorkOrder?.id == workOrder.id {
                self?.refreshStatus()
            }
        }

        view.addDropShadow()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        configureUI()
    }

    func prepareForReuse() {
        workOrder = nil
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
            if workOrder.status == "none" {
                providerStatusLabel?.text = ""
                providerStatusLabel?.isHidden = false
                providerSubStatusLabel?.text = ""
                providerSubStatusLabel?.isHidden = false
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

            if ["en_route", "in_progress"].contains(workOrder.status) {
                if let eta = workOrder.config["eta"] as? [String: Double], let minutes = eta["minutes"], let time = Date().addingTimeInterval(minutes).timeString {
                    providerSubStatusLabel?.text = "\(time) arrival"
                    providerSubStatusLabel?.isHidden = false
                }
            } else {
                providerSubStatusLabel?.text = ""
                providerSubStatusLabel?.isHidden = true
            }
        }
    }
}
