//
//  WorkOrderPinAnnotationView.swift
//  provide
//
//  Created by Kyle Thomas on 7/31/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit

class WorkOrderPinAnnotationView: MKAnnotationView {
    weak var workOrder: WorkOrder!

    @objc dynamic var coordinate: CLLocationCoordinate2D
    @objc dynamic var title: String?
    @objc dynamic var subtitle: String?

    private var rect: CGRect {
        return CGRect(x: 0.0, y: 0.0, width: 50.0, height: 50.0)
    }

    private var imageView: UIImageView {
        let pin = #imageLiteral(resourceName: "provide-pin")
        return UIImageView(image: pin.resize(rect))
    }

    private var profileImageView: ProfileImageView!

    required init(workOrder: WorkOrder) {
        coordinate = workOrder.coordinate!
        super.init(annotation: nil, reuseIdentifier: nil)

        backgroundColor = .clear

        if workOrder.user == nil {
            addSubview(imageView)
            centerOffset = CGPoint(x: 0, y: (rect.height / 2.0) * -1.0)
        } else if let profileImageUrl = workOrder.user.profileImageUrl {
            profileImageView = ProfileImageView(frame: rect)
            profileImageView.setImageWithUrl(profileImageUrl) { [weak self] in
                self?.profileImageView.makeCircular()
                self?.profileImageView.alpha = 1.0
            }
            addSubview(profileImageView)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
