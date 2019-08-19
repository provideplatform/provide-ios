//
//  ConfirmWorkOrderViewController.swift
//  provide
//
//  Created by Kyle Thomas on 8/26/17.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

class ConfirmWorkOrderViewController: ViewController {

    func configure(workOrder: WorkOrder!, categories: [Category], paymentMethod: PaymentMethod!, onWorkOrderConfirmed: @escaping (WorkOrder) -> Void) {
        self.workOrder = workOrder
        self.categories = categories
        self.paymentMethod = paymentMethod
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
    @IBOutlet private weak var topLineView: UIView!
    @IBOutlet private weak var userIconImageView: UIImageView! {
        didSet {
            userIconImageView?.image = userIconImageView?.image?.withRenderingMode(.alwaysTemplate)
            userIconImageView?.tintColor = .lightGray
        }
    }

    @IBAction func categoryChanged(_ sender: CategorySelectionControl) {
        if let categoryId = sender.selectedCategoryId {
            let price = workOrder?.estimatedPriceForCategory(categoryId) ?? 0
            fareEstimateLabel.text = Formatters.currencyFormatter.string(from: price as NSNumber)
            let capacity = CategoryService.shared.capacityForCategoryId(categoryId)
            if capacity > 0 {
                capacityLabel.text = "1-\(capacity)"
            } else {
                capacityLabel.text = "???"
            }

            workOrder?.categoryId = categoryId
            KTNotificationCenter.post(name: .CategorySelectionChanged, object: categoryId)
        } else {
            workOrder?.categoryId = 0
        }
    }

    private(set) var categories: [Category]! {
        didSet {
            categorySelectionControl?.configure(categories: categories)
        }
    }

    var paymentMethod: PaymentMethod! {
        didSet {
            if let paymentMethod = paymentMethod, let last4 = paymentMethod.last4, let icon = paymentMethod.icon {
                creditCardIcon?.image = icon
                creditCardLastFourLabel?.text = "•••• \(last4)"

                if oldValue != nil {
                    workOrder?.removePaymentMethod(paymentMethod)
                }
                workOrder?.addPaymentMethod(paymentMethod)
            } else {
                creditCardIcon?.image = nil
                creditCardLastFourLabel?.text = ""
            }
        }
    }

    private(set) var workOrder: WorkOrder? {
        didSet {
            setViews(hidden: true)
            if workOrder == nil {
                if oldValue != nil {
                    (parent as? ConsumerViewController)?.animateConfirmWorkOrderView(toHidden: true)
                    activityIndicatorView?.stopAnimating()
                }
            } else if let workOrder = workOrder {
                if workOrder.status == "awaiting_schedule" {
                    setViews(hidden: false)

                    distanceEstimateLabel?.text = "\(workOrder.estimatedDistance) miles / \(workOrder.estimatedDuration) minutes"
                    distanceEstimateLabel?.isHidden = false

                    let price = workOrder.estimatedPriceForCategory(1) ?? 0
                    fareEstimateLabel?.text = Formatters.currencyFormatter.string(from: price as NSNumber)
                    fareEstimateLabel?.isHidden = false

                    monkey("👨‍💼 Tap: CONFIRM PRVD") {
                        self.confirmButtonTapped(UIButton())
                    }
                } else if workOrder.status == "pending_acceptance" {
                    setViews(hidden: true)
                    activityIndicatorView?.startAnimating()
                }

                if oldValue == nil {
                    (parent as? ConsumerViewController)?.animateConfirmWorkOrderView(toHidden: false)
                }

                KTNotificationCenter.post(name: .WorkOrderOverviewShouldRender, object: workOrder)
            }
        }
    }

    private func setViews(hidden: Bool) {
        let views: [UIView?] = [
            categorySelectionControl,
            confirmButton,
            creditCardIcon,
            creditCardLastFourLabel,
            userIconImageView,
            capacityLabel,
            distanceEstimateLabel,
            fareEstimateLabel,
            topLineView,
        ]
        views.forEach { $0?.isHidden = hidden }
    }

    func render() {
        // HACK to make the view re-render
        if let categories = categories {
            self.categories = categories
        }

        if let workOrder = workOrder {
            self.workOrder = workOrder
        }

        if let paymentMethod = paymentMethod {
            self.paymentMethod = paymentMethod
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(true, animated: false)
        view.addDropShadow()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        render()
    }

    @IBAction private func confirmButtonTapped(_ sender: UIButton) {
        activityIndicatorView.startAnimating()

        logmoji("👱", "Tapped: CONFIRM PRVD")
        logInfo("Waiting for a provider to accept the request")

        workOrder?.status = "pending_acceptance"
        saveWorkOrder()
    }

    private func saveWorkOrder() {
        setViews(hidden: true)
        activityIndicatorView?.startAnimating()

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
        paymentMethod = nil
        workOrder = nil
    }
}
