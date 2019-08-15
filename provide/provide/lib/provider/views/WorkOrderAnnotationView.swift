//
//  WorkOrderAnnotationView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import Foundation

class WorkOrderAnnotationView: AnnotationView {

    var minutesEta: Int! {
        didSet {
            if let eta = minutesEta, eta > -1 {
                travelMinutesLabel.text = "\(eta)"
                travelMinutesLabel.alpha = 1
                travelTimeUnitsLabel.alpha = 1
                travelEtaActivityIndicatorView.stopAnimating()
            }
        }
    }

    var timeoutAt: Date! {
        didSet {
            if timeoutAt != nil {
                animateTimeoutIndicatorToCompletion()
            }
        }
    }

    @IBOutlet private weak var pinPointerView: UIView!

    @IBOutlet private weak var titleLabel: UILabel!

    @IBOutlet private weak var travelMinutesLabel: UILabel!
    @IBOutlet private weak var travelTimeUnitsLabel: UILabel!
    @IBOutlet private weak var travelEtaActivityIndicatorView: UIActivityIndicatorView!

    private var timeoutIndicatorLayer: CAShapeLayer!

    private var timeoutIndicatorIsAnimated = false

    override func awakeFromNib() {
        super.awakeFromNib()

        canShowCallout = false
        isDraggable = false

        isOpaque = false
        backgroundColor = .clear

        selectedBackgroundColor = resizedSelectedBackgroundColorForRect(CGRect(x: 0.0, y: 0.0, width: containerView.width, height: containerView.frame.height))
        unselectedBackgroundColor = resizedBackgroundColorForRect(CGRect(x: 0.0, y: 0.0, width: containerView.width, height: containerView.frame.height))

        containerView.backgroundColor = unselectedBackgroundColor
        containerView.addDropShadow()
        containerView.roundCorners(25.0)

        pinPointerView.backgroundColor = unselectedBackgroundColor
        pinPointerView.addDropShadow()
        sendSubview(toBack: pinPointerView)

        travelMinutesLabel.alpha = 0

        selectableViews = [containerView, pinPointerView]

        drawTimeoutIndicatorLayer()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        removeGestureRecognizers()

        travelMinutesLabel.alpha = 0
        travelMinutesLabel.text = ""
        travelTimeUnitsLabel.alpha = 0
        travelEtaActivityIndicatorView.startAnimating()

        resetTimeoutIndicatorLayer()
        drawTimeoutIndicatorLayer()
    }

    private func drawTimeoutIndicatorLayer() {
        timeoutIndicatorLayer = CAShapeLayer()
        timeoutIndicatorLayer.path = UIBezierPath(arcCenter: travelEtaActivityIndicatorView.center,
                                                  radius: travelEtaActivityIndicatorView.frame.width / 1.1,
                                                  startAngle: .pi,
                                                  endAngle: .pi * 2.0 + .pi,
                                                  clockwise: true).cgPath
        timeoutIndicatorLayer.backgroundColor = UIColor.clear.cgColor
        timeoutIndicatorLayer.fillColor = nil
        timeoutIndicatorLayer.strokeColor = UIColor.white.cgColor
        timeoutIndicatorLayer.lineWidth = 2.0
        layer.addSublayer(timeoutIndicatorLayer)

        let dashedLayer = CAShapeLayer()
        dashedLayer.strokeColor = UIColor(white: 1.0, alpha: 0.75).cgColor
        dashedLayer.fillColor = nil
        dashedLayer.lineDashPattern = [2, 3]
        dashedLayer.lineJoin = "round"
        dashedLayer.lineWidth = 1.5
        dashedLayer.path = timeoutIndicatorLayer.path
        layer.insertSublayer(dashedLayer, below: timeoutIndicatorLayer)
    }

    private func resetTimeoutIndicatorLayer() {
        timeoutIndicatorLayer?.removeFromSuperlayer()
        timeoutIndicatorLayer = nil
        timeoutIndicatorIsAnimated = false
    }

    private func animateTimeoutIndicatorToCompletion() {
        if timeoutIndicatorIsAnimated {
            return
        }

        timeoutIndicatorIsAnimated = true
        let duration = timeoutAt.timeIntervalSinceNow

        DispatchQueue.main.async(qos: .userInteractive) { [weak self] in
            if let strongSelf = self, let timeoutIndicatorLayer = strongSelf.timeoutIndicatorLayer {
                let animation = CABasicAnimation(keyPath: "strokeEnd")
                animation.fromValue = 0.0
                animation.duration = duration
                animation.fillMode = kCAFillModeForwards
                timeoutIndicatorLayer.add(animation, forKey: "animation")
            }
        }
    }

    private func backgroundImageForRect(_ rect: CGRect) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0.0)
        let image = Color.annotationViewBackgroundImage()
        image.draw(in: rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage!
    }

    private func resizedBackgroundColorForRect(_ rect: CGRect) -> UIColor {
        return UIColor(patternImage: backgroundImageForRect(rect)).withAlphaComponent(0.70)
    }

    private func resizedSelectedBackgroundColorForRect(_ rect: CGRect) -> UIColor {
        return UIColor(patternImage: backgroundImageForRect(rect)).withAlphaComponent(0.90)
    }
}
