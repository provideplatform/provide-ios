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
    func tintColorForBlueprintPinView(view: BlueprintPinView) -> UIColor
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
                    } else {
                        self.category = nil
                    }
                }
            }
        }
    }

    var category: Category! {
        didSet {
            dispatch_after_delay(0.0) {
                self.refresh()
            }
        }
    }

    private weak var workOrder: WorkOrder! {
        if let annotation = annotation {
            return annotation.workOrder
        }
        return nil
    }

    weak var delegate: BlueprintPinViewDelegate! {
        didSet {
            self.category = delegate?.categoryForBlueprintPinView(self)
        }
    }

    var point: CGPoint!

    var overlayViewBoundingBox: CGRect! {
        if let point = annotation.point {
            return CGRect(x: point[0] - 250.0, y: point[1] - 250.0, width: 500.0, height: 500.0)
        }
        return nil
    }

    private var abbreviationLabel: UILabel!

    private var gestureRecognizer: UITapGestureRecognizer!

    private var timer: NSTimer!

    required init(annotation: Annotation!) {
        super.init(frame: CGRectZero)

        self.annotation = annotation

        if let point = annotation?.point {
            self.point = CGPoint(x: point[0], y: point[1])
        }

        if let tintColor = annotation?.workOrder?.statusColor {
            self.tintColor = tintColor
        }

        image = UIImage(named: "map-pin")!.scaledToWidth(50.0).imageWithRenderingMode(.AlwaysTemplate)
        bounds = CGRect(x: 0.0, y: 0.0, width: image!.size.width, height: image!.size.height)

        initWorkOrderChangedNotificationObserver()
    }

    required init(delegate: BlueprintPinViewDelegate, annotation: Annotation) {
        super.init(frame: CGRectZero)

        self.delegate = delegate
        self.annotation = annotation

        if let point = annotation.point {
            self.point = CGPoint(x: point[0], y: point[1])
        }

        if let tintColor = annotation.workOrder?.statusColor {
            self.tintColor = tintColor
        }

        image = UIImage(named: "map-pin")!.scaledToWidth(50.0).imageWithRenderingMode(.AlwaysTemplate)
        bounds = CGRect(x: 0.0, y: 0.0, width: image!.size.width, height: image!.size.height)

        initWorkOrderChangedNotificationObserver()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        initWorkOrderChangedNotificationObserver()
    }

    private func refresh() {
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

        if let tintColor = delegate?.tintColorForBlueprintPinView(self) {
            self.tintColor = tintColor
        } else if let workOrder = workOrder {
            tintColor = workOrder.statusColor
        }
    }

    func initWorkOrderChangedNotificationObserver() {
        NSNotificationCenter.defaultCenter().addObserverForName("WorkOrderChanged") { notification in
            if let workOrder = notification.object as? WorkOrder {
                if let wo = self.workOrder {
                    if workOrder.id == wo.id {
                        if let delegate = self.delegate {
                            if let category = delegate.categoryForBlueprintPinView(self) {
                                self.category = category
                            }
                        }
                    }
                }
            }
        }
    }

    func attachGestureRecognizer() {
        userInteractionEnabled = true
        gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(BlueprintPinView.pinSelected(_:)))
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

    func setScale(zoomScale: CGFloat) {
        transform = CGAffineTransformMakeScale(1.0 / zoomScale, 1.0 / zoomScale)
    }

    private func renderAbbreviation(abbreviation: String) {
        if abbreviationLabel == nil {
            abbreviationLabel = UILabel()
            abbreviationLabel.backgroundColor = UIColor.clearColor()
            abbreviationLabel.textColor = UIColor.whiteColor()
            abbreviationLabel.font = UIFont(name: "Exo2-Bold", size: 26.0)!
        }

        abbreviationLabel.text = abbreviation
        abbreviationLabel.sizeToFit()
        if let image = image {
            abbreviationLabel.frame = CGRect(x: (image.size.width / 2.0) - (abbreviationLabel.frame.width / 2.0),
                                             y: (image.size.height / 2.0) - (abbreviationLabel.frame.height / 1.5),
                                             width: abbreviationLabel.frame.width,
                                             height: abbreviationLabel.frame.height)
        }
        abbreviationLabel.alpha = 1.0

        if abbreviationLabel.superview == nil {
            addSubview(abbreviationLabel)
            bringSubviewToFront(abbreviationLabel)
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
