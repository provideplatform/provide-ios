//
//  WorkOrderAnnotationView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

class WorkOrderAnnotationView: AnnotationView {

    private let defaultPadding = UIEdgeInsets(top: 5, left: 0, bottom: 100, right: 0)

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

    @IBOutlet private weak var pinPointerView: UIView!

    @IBOutlet private weak var titleLabel: UILabel!

    @IBOutlet private weak var travelMinutesLabel: UILabel!
    @IBOutlet private weak var travelTimeUnitsLabel: UILabel!
    @IBOutlet private weak var travelEtaActivityIndicatorView: UIActivityIndicatorView!

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
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        travelMinutesLabel.alpha = 0
        travelMinutesLabel.text = ""
        travelTimeUnitsLabel.alpha = 0
        travelEtaActivityIndicatorView.startAnimating()
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
