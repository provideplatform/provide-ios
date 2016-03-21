//
//  BlueprintPinView.swift
//  provide
//
//  Created by Kyle Thomas on 3/7/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

protocol BlueprintPinViewDelegate: NSObjectProtocol {
    func categoryForBlueprintPinView(view: BlueprintPinView) -> Category!
    func blueprintPinViewWasSelected(view: BlueprintPinView)

//    func blueprintForBlueprintPolygonView(view: BlueprintPolygonView) -> Attachment!
//    func blueprintPolygonViewDidClose(view: BlueprintPolygonView)
//    func blueprintPolygonViewCanBeResized(view: BlueprintPolygonView) -> Bool
//    func blueprintPolygonView(view: BlueprintPolygonView, colorForOverlayView overlayView: UIView) -> UIColor
//    func blueprintPolygonView(view: BlueprintPolygonView, opacityForOverlayView overlayView: UIView) -> CGFloat
//    func blueprintPolygonView(view: BlueprintPolygonView, layerForOverlayView overlayView: UIView, inBoundingBox boundingBox: CGRect) -> CALayer!
//    func blueprintPolygonView(view: BlueprintPolygonView, didSelectOverlayView overlayView: UIView, atPoint point: CGPoint, inPath path: CGPath)
//    func blueprintPolygonView(view: BlueprintPolygonView, didUpdateAnnotation annotation: Annotation)
}

class BlueprintPinView: UIImageView, UIGestureRecognizerDelegate {

    var annotation: Annotation! {
        didSet {
            if let annotation = annotation {
                if let workOrder = annotation.workOrder {
                    if let category = workOrder.category {
                        self.category = category
                    }
                }
            }
        }
    }

    var category: Category! {
        didSet {
            if let category = category {
                if let iconImageUrl = category.iconImageUrl {
                    ImageService.sharedService().fetchImage(iconImageUrl, cacheOnDisk: true, downloadOptions: .ContinueInBackground,
                        onDownloadSuccess: { image in
                            print("TODO: embed category icon in pin view \(image)")
                        },
                        onDownloadFailure: { error in

                        },
                        onDownloadProgress: { receivedSize, expectedSize in

                        }
                    )
                } else if let abbreviation = category.abbreviation {
                    renderAbbreviation(abbreviation)
                }
            }
        }
    }

    weak var delegate: BlueprintPinViewDelegate! {
        didSet {
            if let delegate = delegate {
                if let category = delegate.categoryForBlueprintPinView(self) {
                    self.category = category
                }
            }
        }
    }

    var point: CGPoint!

    var overlayViewBoundingBox: CGRect! {
        if let point = annotation.point {
            return CGRect(x: point[0], y: point[1], width: 100.0, height: 100.0)
        }
        return nil
    }

    private var gestureRecognizer: UITapGestureRecognizer!

    private var timer: NSTimer!

    required init(annotation: Annotation!) {
        super.init(frame: CGRectZero)

        self.annotation = annotation

        if let point = annotation?.point {
            self.point = CGPoint(x: point[0], y: point[1])
        }

        image = UIImage(named: "map-pin")!.scaledToWidth(75.0)
        bounds = CGRect(x: 0.0, y: 0.0, width: image!.size.width, height: image!.size.height)
    }

    required init(delegate: BlueprintPinViewDelegate, annotation: Annotation) {
        super.init(frame: CGRectZero)

        self.delegate = delegate
        self.annotation = annotation

        if let point = annotation.point {
            self.point = CGPoint(x: point[0], y: point[1])
        }

        image = UIImage(named: "map-pin")!.scaledToWidth(75.0)
        bounds = CGRect(x: 0.0, y: 0.0, width: image!.size.width, height: image!.size.height)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func attachGestureRecognizer() {
        userInteractionEnabled = true
        gestureRecognizer = UITapGestureRecognizer(target: self, action: "pinSelected:")
        addGestureRecognizer(gestureRecognizer)
    }

    private func removeGestureRecognizer() {
        if let gestureRecognizer = gestureRecognizer {
            removeGestureRecognizer(gestureRecognizer)
            self.gestureRecognizer = nil
            userInteractionEnabled = false
        }
    }

    private func reset(suppressDelegateNotification: Bool = false) {
        point = nil

        removeGestureRecognizer()
    }

    func resignFirstResponder(suppressDelegateNotification: Bool = false) -> Bool {
        reset(suppressDelegateNotification)
        return super.resignFirstResponder()
    }

    func pinSelected(gestureRecognizer: UITapGestureRecognizer) {
        delegate?.blueprintPinViewWasSelected(self)
    }

    func redraw() {
        reset()
        attachGestureRecognizer()
    }

    private func renderAbbreviation(abbreviation: String) {
        let abbreviationLabel = UILabel()
        abbreviationLabel.backgroundColor = UIColor.clearColor() //Color.annotationViewBackgroundImageColor().colorWithAlphaComponent(0.8)
        abbreviationLabel.textColor = UIColor.whiteColor()
        abbreviationLabel.text = abbreviation
        abbreviationLabel.font = UIFont(name: "Exo2-Bold", size: 32.0)!
        abbreviationLabel.sizeToFit()
        abbreviationLabel.frame = CGRectOffset(abbreviationLabel.frame, (image!.size.width / 2.0) - (abbreviationLabel.frame.width / 2.0), 20.0)
        //abbreviationLabel.layer.cornerRadius = abbreviationLabel.frame.width / 2
        abbreviationLabel.alpha = 1.0

        addSubview(abbreviationLabel)
        bringSubviewToFront(abbreviationLabel)
    }
}
