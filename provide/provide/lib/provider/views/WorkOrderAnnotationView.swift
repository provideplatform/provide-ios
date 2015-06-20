//
//  WorkOrderAnnotationView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

class WorkOrderAnnotationView: AnnotationView {

    private let defaultPadding = UIEdgeInsetsMake(5, 0, 100, 0)

    var minutesEta: Int! {
        didSet {
            if let eta = minutesEta {
                if eta > -1 {
                    travelMinutesLabelView.text = "\(eta)"
                    travelMinutesLabelView.alpha = 1
                    travelTimeUnitsLabelView.alpha = 1
                    travelEtaActivityIndicatorView.stopAnimating()
                }
            }
        }
    }

    @IBOutlet private weak var pinPointerView: UIView!

    @IBOutlet private weak var titleLabel: UILabel!

    @IBOutlet private weak var travelMinutesLabelView: UILabel!
    @IBOutlet private weak var travelTimeUnitsLabelView: UILabel!
    @IBOutlet private weak var travelEtaActivityIndicatorView: UIActivityIndicatorView!

    override func awakeFromNib() {
        super.awakeFromNib()

        canShowCallout = false
        draggable = false

        opaque = false
        backgroundColor = UIColor.clearColor()

        selectedBackgroundColor = resizedSelectedBackgroundColorForRect(CGRect(x: 0.0, y: 0.0, width: containerView.frame.width, height: containerView.frame.height))
        unselectedBackgroundColor = resizedBackgroundColorForRect(CGRect(x: 0.0, y: 0.0, width: containerView.frame.width, height: containerView.frame.height))

        containerView.backgroundColor = unselectedBackgroundColor
        containerView.addDropShadow()
        containerView.roundCorners(25.0)

        pinPointerView.backgroundColor = unselectedBackgroundColor //resizedBackgroundColorForRect(CGRect(x: 0.0, y: 0.0, width: pinPointerView.frame.width, height: pinPointerView.frame.height))
        pinPointerView.addDropShadow()
        sendSubviewToBack(pinPointerView)

        travelMinutesLabelView.alpha = 0

        selectableViews = [containerView, pinPointerView]
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        travelMinutesLabelView.alpha = 0
        travelMinutesLabelView.text = ""
        travelTimeUnitsLabelView.alpha = 0
        travelEtaActivityIndicatorView.startAnimating()
    }

    private func backgroundImageForRect(rect: CGRect) -> UIImage! {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0.0)
        let image = Color.annotationViewBackgroundImage()
        image.drawInRect(rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }

    private func resizedBackgroundColorForRect(rect: CGRect) -> UIColor! {
        return UIColor(patternImage: backgroundImageForRect(rect)).colorWithAlphaComponent(0.70)
    }

    private func resizedSelectedBackgroundColorForRect(rect: CGRect) -> UIColor! {
        return UIColor(patternImage: backgroundImageForRect(rect)).colorWithAlphaComponent(0.90)
    }
}
