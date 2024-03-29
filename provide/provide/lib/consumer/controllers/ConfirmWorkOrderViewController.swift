//
//  ConfirmWorkOrderViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/26/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

class ConfirmWorkOrderViewController: ViewController {

    func configure(workOrder: WorkOrder!, categories: [Category], onWorkOrderConfirmed: @escaping (WorkOrder) -> Void) {
        self.workOrder = workOrder
        self.categories = categories
        self.onWorkOrderConfirmed = onWorkOrderConfirmed
    }

    private var onWorkOrderConfirmed: ((WorkOrder) -> Void)!

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var categorySelectionControl: CategorySelectionControl!
    @IBOutlet private weak var confirmButton: UIButton!
    @IBOutlet private weak var creditCardIcon: UIImageView!
    @IBOutlet private weak var creditCardLastFourLabel: UILabel!
    @IBOutlet private weak var capacityLabel: UILabel!
    @IBOutlet private weak var distanceEstimateLabel: UILabel!
    @IBOutlet private weak var fareEstimateLabel: UILabel!
    @IBOutlet private weak var userIconImageView: UIImageView! {
        didSet {
            userIconImageView?.image = userIconImageView?.image?.withRenderingMode(.alwaysTemplate)
            userIconImageView?.tintColor = .lightGray
        }
    }

    @IBAction func categoryChanged(_ sender: CategorySelectionControl) {
        let categoryId = sender.selectedIndex + 1 // TODO: Make robust
        let price = workOrder?.estimatedPriceForCategory(categoryId) ?? 0
        fareEstimateLabel.text = Formatters.currencyFormatter.string(from: price as NSNumber)
        capacityLabel.text = "1-\(CategoryService.shared.capacityForCategoryId(categoryId))"
        workOrder?.categoryId = categoryId
        KTNotificationCenter.post(name: .CategorySelectionChanged, object: categoryId)
    }

    private(set) var categories: [Category]! {
        didSet {
            categorySelectionControl?.configure(categories: categories)
        }
    }

    private(set) var workOrder: WorkOrder? {
        didSet {
            if workOrder == nil {
                if oldValue != nil {
                    (parent as? ConsumerViewController)?.animateConfirmWorkOrderView(toHidden: true)
                    self.activityIndicatorView.stopAnimating()
                    self.setViews(hidden: false)
                }
            } else if let workOrder = workOrder {
                if workOrder.status == "awaiting_schedule" {
                    distanceEstimateLabel.text = "\(workOrder.estimatedDistance) miles / \(workOrder.estimatedDuration) minutes"
                    distanceEstimateLabel.isHidden = false

                    let price = workOrder.estimatedPriceForCategory(1) ?? 0
                    fareEstimateLabel.text = Formatters.currencyFormatter.string(from: price as NSNumber)
                    fareEstimateLabel.isHidden = false

                    // self.creditCardLastFour.text = "" // TODO
                    // self.capacity.text = "" // TODO

                    monkey("👨‍💼 Tap: CONFIRM PRVD") {
                        self.confirmButtonTapped(UIButton())
                    }
                } else if workOrder.status == "pending_acceptance" {
                    setViews(hidden: true)
                    activityIndicatorView.startAnimating()
                }

                if oldValue == nil {
                    (parent as? ConsumerViewController)?.animateConfirmWorkOrderView(toHidden: false)
                }

                KTNotificationCenter.post(name: .WorkOrderOverviewShouldRender, object: workOrder)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addDropShadow()
    }

    private func setViews(hidden: Bool) {
        let views: [UIView] = [
            categorySelectionControl,
            confirmButton,
            creditCardIcon,
            creditCardLastFourLabel,
            userIconImageView,
            capacityLabel,
            distanceEstimateLabel,
            fareEstimateLabel,
        ]
        views.forEach { $0.isHidden = hidden }
    }

    @IBAction private func confirmButtonTapped(_ sender: UIButton) {
        setViews(hidden: true)
        activityIndicatorView.startAnimating()

        logmoji("👱", "Tapped: CONFIRM PRVD")
        logInfo("Waiting for a provider to accept the request")

        workOrder?.status = "pending_acceptance"
        saveWorkOrder()
    }

    private func saveWorkOrder() {
        // TODO: show progress HUD

        workOrder?.save(onSuccess: { [weak self] statusCode, mappingResult in
            if statusCode == 201 {
                if let workOrder = mappingResult?.firstObject as? WorkOrder {
                    logInfo("Created work order for hire: \(workOrder)")
                    self?.onWorkOrderConfirmed(workOrder)
                }
            }
        }, onError: { err, statusCode, responseString in
            logWarn("Failed to create work order for hire (\(statusCode))")
        })
    }

    func prepareForReuse() {
        workOrder = nil
    }

    func confirmWorkOrderWithOrigin(_ origin: Contact, destination: Contact) {
        let latitude = origin.latitude
        let longitude = origin.longitude

        logInfo("Creating work order from \(latitude),\(longitude) -> \(destination.desc!)")

        // TODO: show progress HUD

        let pendingWorkOrder = WorkOrder()
        pendingWorkOrder.desc = destination.desc
        if let cfg = destination.data {
            pendingWorkOrder.config = [
                "origin": origin.toDictionary(),
                "destination": cfg,
            ]
        }

        pendingWorkOrder.save(onSuccess: { [weak self] statusCode, mappingResult in
            if let workOrder = mappingResult?.firstObject as? WorkOrder {
                logInfo("Created work order for hire: \(workOrder)")
                WorkOrderService.shared.setWorkOrders([workOrder])
                self?.workOrder = workOrder
            }
        }, onError: { err, statusCode, responseString in
            logWarn("Failed to create work order for hire (\(statusCode))")
        })
    }
}
