//
//  WorkOrderDestinationConfirmationViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class WorkOrderDestinationConfirmationViewController: ViewController, WorkOrdersViewControllerDelegate {

    private weak var targetView: UIView?
    private(set) weak var workOrdersViewControllerDelegate: WorkOrdersViewControllerDelegate?
    private var onConfirmationReceived: VoidBlock!
    private var sourceNavigationItem: UINavigationItem!

    func configure(delegate: WorkOrdersViewControllerDelegate, targetView: UIView, sourceNavigationItem: UINavigationItem, onConfirm: @escaping VoidBlock) {
        self.workOrdersViewControllerDelegate = delegate
        self.sourceNavigationItem = sourceNavigationItem
        self.targetView = targetView
        self.onConfirmationReceived = onConfirm
    }

    private var minutesEta: Int? {
        didSet {
            updateEtaLabel(eta: minutesEta)
        }
    }

    var timeoutAt: Date! {
        didSet {
            if timeoutAt != nil {
                animateTimeoutIndicatorToCompletion()
            }
        }
    }

    private func updateEtaLabel(eta: Int?) {
        arrivalEtaEstimateLabel.text = eta.map { "ARRIVAL TIME IS APPROXIMATELY \($0) MIN" } ?? ""
        arrivalEtaEstimateLabel.alpha = eta == nil ? 0 : 1
    }

    @IBOutlet private weak var arrivalEtaEstimateLabel: UILabel!
    @IBOutlet private weak var confirmStartWorkOrderButton: RoundedButton!

    private var timeoutIndicatorLayer: CAShapeLayer!
    private var timeoutIndicatorIsAnimated = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        minutesEta = nil
        confirmStartWorkOrderButton?.onTouchUpInsideCallback = onConfirmationReceived

        timeoutAt = nil

        if WorkOrderService.shared.nextWorkOrder != nil {
            confirmStartWorkOrderButton.setTitle("ACCEPT REQUEST", for: .normal) // FIXME
            minutesEta = WorkOrderService.shared.nextWorkOrderDrivingEtaMinutes
        } else if WorkOrderService.shared.inProgressWorkOrder != nil {
            confirmStartWorkOrderButton.setTitle("CONFIRM DESTINATION", for: .normal) // FIXME

            // refresh eta
            LocationService.shared.resolveCurrentLocation { [weak self] location in
                WorkOrderService.shared.fetchInProgressWorkOrderDrivingEtaFromCoordinate(location.coordinate) { [weak self] _, minutesEta in
                    self?.minutesEta = minutesEta
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        drawTimeoutIndicatorLayer()
        if let timeoutAt = WorkOrderService.shared.nextWorkOrder?.nextTimeoutAtDate {
            self.timeoutAt = timeoutAt

            DispatchQueue.main.asyncAfter(deadline: .now() + timeoutAt.timeIntervalSinceNow) { [weak self] in
                logInfo("Preemptively timing out unaccepted work order prior to receiving notification")
                self?.cancel(nil)
            }
        }

        monkey("👨‍✈️ Tap: \(confirmStartWorkOrderButton.titleLabel!.text!)", after: 2) {
            self.onConfirmationReceived()
        }
    }

    // MARK: Rendering

    func render() {
        let frame = CGRect(
            x: 0.0,
            y: targetView?.height ?? 0,
            width: targetView?.width ?? 0,
            height: view.height
        )

        view.alpha = 0.0
        view.frame = frame

        view.addDropShadow(radius: 2.5, opacity: 1)

        targetView?.addSubview(view)

        // setup navigation item
        if let navigationItem = sourceNavigationItem {
            navigationItem.title = "CONFIRMATION"
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel(_:)))
        }

        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseIn, animations: {
            self.view.alpha = 1
            self.view.frame = CGRect(
                x: frame.origin.x,
                y: frame.origin.y - self.view.height,
                width: frame.width,
                height: frame.height
            )
        })
    }

    // MARK: Status indicator

    func showProgressIndicator() {
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
            self.confirmStartWorkOrderButton.alpha = 0
            self.arrivalEtaEstimateLabel.alpha = 0
        }, completion: { completed in
            self.showActivity()
        })
    }

    private func _hideProgressIndicator() {
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
            self.confirmStartWorkOrderButton.alpha = 1
            self.arrivalEtaEstimateLabel.alpha = 1
        }, completion: { completed in
            self.hideActivity()
        })
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "WorkOrderDestinationConfirmationViewControllerUnwindSegue":
            assert(segue.source is WorkOrderDestinationConfirmationViewController && segue.destination is WorkOrdersViewController)
            unwind()
        default:
            break
        }
    }

    private func unwind() {
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseIn, animations: {
            self.view.alpha = 0
            self.view.frame = CGRect(
                x: self.view.frame.origin.x,
                y: self.view.frame.origin.y + self.view.height,
                width: self.view.width,
                height: self.view.height
            )
        }, completion: { completed in
            self.view.removeFromSuperview()
            self.clearNavigationItem()
        })
    }

    private func clearNavigationItem() {
        if let navigationItem = sourceNavigationItem {
            navigationItem.title = nil

            navigationItem.leftBarButtonItems = []
            navigationItem.rightBarButtonItems = []
        }

        workOrdersViewControllerDelegate?.navigationControllerNavBarButtonItemsShouldBeResetForViewController?(self)
    }

    // MARK: Timeout indicator

    private func drawTimeoutIndicatorLayer() {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: confirmStartWorkOrderButton.width, y: 0.0))
        path.addLine(to: CGPoint(x: 0.0, y: 0.0))

        timeoutIndicatorLayer = CAShapeLayer()
        timeoutIndicatorLayer.path = path.reversing().cgPath
        timeoutIndicatorLayer.backgroundColor = nil
        timeoutIndicatorLayer.fillColor = UIColor.clear.cgColor
        timeoutIndicatorLayer.strokeColor = UIColor.white.cgColor
        timeoutIndicatorLayer.lineWidth = confirmStartWorkOrderButton.height * 10.0
        timeoutIndicatorLayer.cornerRadius = confirmStartWorkOrderButton.layer.cornerRadius
        timeoutIndicatorLayer.opacity = 0.35

        confirmStartWorkOrderButton.layer.masksToBounds = true
        confirmStartWorkOrderButton.layer.addSublayer(timeoutIndicatorLayer)
    }

    private func animateTimeoutIndicatorToCompletion() {
        if timeoutIndicatorIsAnimated {
            return
        }

        timeoutIndicatorIsAnimated = true
        let duration = timeoutAt.timeIntervalSinceNow

        DispatchQueue.main.async(qos: .userInteractive) { [weak self] in
            if let strongSelf = self, let timeoutIndicatorLayer = strongSelf.timeoutIndicatorLayer {
                let animation = CABasicAnimation(keyPath: "strokeStart")
                animation.fromValue = 1.0
                animation.toValue = 0.0
                animation.duration = duration
                animation.fillMode = kCAFillModeForwards
                timeoutIndicatorLayer.add(animation, forKey: "animation")
            }
        }
    }

    // MARK: Actions

    @objc private func cancel(_: UIBarButtonItem?) {
        clearNavigationItem()
        workOrdersViewControllerDelegate?.confirmationCanceledForWorkOrderViewController?(self)
    }

    // MARK: WorkOrdersViewControllerDelegate

    func drivingEtaToNextWorkOrderChanged(_ minutesEta: Int) {
        self.minutesEta = minutesEta
    }
}
