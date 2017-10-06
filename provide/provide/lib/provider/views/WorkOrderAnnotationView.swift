//
//  WorkOrderAnnotationView.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

class WorkOrderAnnotationView: AnnotationView {

    fileprivate let defaultPadding = UIEdgeInsets(top: 5, left: 0, bottom: 100, right: 0)

    var minutesEta: Int! {
        didSet {
            if let eta = minutesEta, eta > -1 {
                travelMinutesLabelView.text = "\(eta)"
                travelMinutesLabelView.alpha = 1
                travelTimeUnitsLabelView.alpha = 1
                travelEtaActivityIndicatorView.stopAnimating()
            }
        }
    }

    @IBOutlet fileprivate weak var pinPointerView: UIView!

    @IBOutlet fileprivate weak var titleLabel: UILabel!

    @IBOutlet fileprivate weak var travelMinutesLabelView: UILabel!
    @IBOutlet fileprivate weak var travelTimeUnitsLabelView: UILabel!
    @IBOutlet fileprivate weak var travelEtaActivityIndicatorView: UIActivityIndicatorView!

    override func awakeFromNib() {
        super.awakeFromNib()

        canShowCallout = false
        isDraggable = false

        isOpaque = false
        backgroundColor = .clear

        selectedBackgroundColor = resizedSelectedBackgroundColorForRect(CGRect(x: 0.0, y: 0.0, width: containerView.frame.width, height: containerView.frame.height))
        unselectedBackgroundColor = resizedBackgroundColorForRect(CGRect(x: 0.0, y: 0.0, width: containerView.frame.width, height: containerView.frame.height))

        containerView.backgroundColor = unselectedBackgroundColor
        containerView.addDropShadow()
        containerView.roundCorners(25.0)

        pinPointerView.backgroundColor = unselectedBackgroundColor
        pinPointerView.addDropShadow()
        sendSubview(toBack: pinPointerView)

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

    fileprivate func backgroundImageForRect(_ rect: CGRect) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0.0)
        let image = Color.annotationViewBackgroundImage()
        image.draw(in: rect)
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage!
    }

    fileprivate func resizedBackgroundColorForRect(_ rect: CGRect) -> UIColor {
        return UIColor(patternImage: backgroundImageForRect(rect)).withAlphaComponent(0.70)
    }

    fileprivate func resizedSelectedBackgroundColorForRect(_ rect: CGRect) -> UIColor {
        return UIColor(patternImage: backgroundImageForRect(rect)).withAlphaComponent(0.90)
    }
}
