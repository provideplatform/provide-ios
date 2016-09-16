//
//  FloorplanPinView.swift
//  provide
//
//  Created by Kyle Thomas on 3/7/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import KTSwiftExtensions

protocol FloorplanPinViewDelegate: NSObjectProtocol {
    func categoryForFloorplanPinView(_ view: FloorplanPinView) -> Category!
    func tintColorForFloorplanPinView(_ view: FloorplanPinView) -> UIColor
    func floorplanPinViewWasSelected(_ view: FloorplanPinView)

//    func floorplanForFloorplanPolygonView(view: FloorplanPolygonView) -> Attachment!
//    func floorplanPolygonViewDidClose(view: FloorplanPolygonView)
//    func floorplanPolygonViewCanBeResized(view: FloorplanPolygonView) -> Bool
//    func floorplanPolygonView(view: FloorplanPolygonView, colorForOverlayView overlayView: UIView) -> UIColor
//    func floorplanPolygonView(view: FloorplanPolygonView, opacityForOverlayView overlayView: UIView) -> CGFloat
//    func floorplanPolygonView(view: FloorplanPolygonView, layerForOverlayView overlayView: UIView, inBoundingBox boundingBox: CGRect) -> CALayer!
//    func floorplanPolygonView(view: FloorplanPolygonView, didSelectOverlayView overlayView: UIView, atPoint point: CGPoint, inPath path: CGPath)
//    func floorplanPolygonView(view: FloorplanPolygonView, didUpdateAnnotation annotation: Annotation)
}

class FloorplanPinView: UIImageView, UIGestureRecognizerDelegate {

    var annotation: Annotation! {
        didSet {
            if let workOrder = workOrder {
                if let category = workOrder.category {
                    self.category = category
                } else {
                    self.category = nil
                }
            }
        }
    }

    var category: Category! {
        didSet {
            if Thread.isMainThread {
                self.refresh()
            } else {
                dispatch_after_delay(0.0) {
                    self.refresh()
                }
            }
        }
    }

    weak var workOrder: WorkOrder! {
        if let annotation = annotation {
            return annotation.workOrder
        }
        return nil
    }

    weak var delegate: FloorplanPinViewDelegate! {
        didSet {
            self.category = delegate?.categoryForFloorplanPinView(self)
        }
    }

    var point: CGPoint!

    var overlayViewBoundingBox: CGRect! {
        if let point = annotation.point {
            return CGRect(x: point[0] - 250.0, y: point[1] - 250.0, width: 500.0, height: 500.0)
        }
        return nil
    }

    fileprivate var abbreviationLabel: UILabel!

    fileprivate var gestureRecognizer: UITapGestureRecognizer!

    fileprivate var timer: Timer!

    required init(annotation: Annotation!) {
        super.init(frame: CGRect.zero)

        self.annotation = annotation

        if let point = annotation?.point {
            self.point = CGPoint(x: point[0], y: point[1])
        }

        if let tintColor = annotation?.workOrder?.statusColor {
            self.tintColor = tintColor
        }

        image = UIImage(named: "map-pin")!.scaledToWidth(50.0).withRenderingMode(.alwaysTemplate)
        bounds = CGRect(x: 0.0, y: 0.0, width: image!.size.width, height: image!.size.height)

        initWorkOrderChangedNotificationObserver()
    }

    required init(delegate: FloorplanPinViewDelegate, annotation: Annotation) {
        super.init(frame: CGRect.zero)

        self.delegate = delegate
        self.annotation = annotation

        if let point = annotation.point {
            self.point = CGPoint(x: point[0], y: point[1])
        }

        if let tintColor = annotation.workOrder?.statusColor {
            self.tintColor = tintColor
        }

        image = UIImage(named: "map-pin")!.scaledToWidth(50.0).withRenderingMode(.alwaysTemplate)
        bounds = CGRect(x: 0.0, y: 0.0, width: image!.size.width, height: image!.size.height)

        initWorkOrderChangedNotificationObserver()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        initWorkOrderChangedNotificationObserver()
    }

    fileprivate func refresh() {
        if let category = category {
            if let iconImageUrl = category.iconImageUrl {
                ImageService.sharedService().fetchImage(iconImageUrl, cacheOnDisk: true, downloadOptions: .continueInBackground,
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

        if let tintColor = delegate?.tintColorForFloorplanPinView(self) {
            self.tintColor = tintColor
        } else if let workOrder = workOrder {
            tintColor = workOrder.statusColor
        }
    }

    func initWorkOrderChangedNotificationObserver() {
        NotificationCenter.default.addObserverForName("WorkOrderChanged") { notification in
            if let workOrder = notification.object as? WorkOrder {
                if let wo = self.workOrder {
                    if workOrder.id == wo.id {
                        if let delegate = self.delegate {
                            if let category = delegate.categoryForFloorplanPinView(self) {
                                self.category = category
                            }
                        }
                    }
                }
            }
        }
    }

    func attachGestureRecognizer() {
        isUserInteractionEnabled = true
        gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(FloorplanPinView.pinSelected(_:)))
        addGestureRecognizer(gestureRecognizer)
    }

    fileprivate func removeGestureRecognizer() {
        if let gestureRecognizer = gestureRecognizer {
            removeGestureRecognizer(gestureRecognizer)
            self.gestureRecognizer = nil
            isUserInteractionEnabled = false
        }
    }

    fileprivate func reset(_ suppressDelegateNotification: Bool = false) {
        point = nil

        removeGestureRecognizer()
    }

    func resignFirstResponder(_ suppressDelegateNotification: Bool = false) -> Bool {
        reset(suppressDelegateNotification)
        return super.resignFirstResponder()
    }

    func pinSelected(_ gestureRecognizer: UITapGestureRecognizer) {
        delegate?.floorplanPinViewWasSelected(self)
    }

    func redraw() {
        reset()
        attachGestureRecognizer()
    }

    func setScale(_ zoomScale: CGFloat) {
        transform = CGAffineTransform(scaleX: 1.0 / zoomScale, y: 1.0 / zoomScale)
    }

    fileprivate func renderAbbreviation(_ abbreviation: String) {
        if abbreviationLabel == nil {
            abbreviationLabel = UILabel()
            abbreviationLabel.backgroundColor = UIColor.clear
            abbreviationLabel.textColor = UIColor.white
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
            bringSubview(toFront: abbreviationLabel)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
