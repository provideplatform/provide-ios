//
//  WorkOrderPinAnnotationView.swift
//  provide
//
//  Created by Kyle Thomas on 7/31/15.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
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

    required init(workOrder: WorkOrder, forcePin: Bool = false) {
        coordinate = workOrder.coordinate!
        super.init(annotation: nil, reuseIdentifier: nil)

        backgroundColor = .clear
        centerOffset = CGPoint(x: (rect.width / 2.0) * -1.0,
                               y: (rect.height / 2.0) * -1.0)

        if workOrder.user == nil || workOrder.status == "in_progress" || forcePin {
            centerOffset.y = rect.height * -1.0
            addSubview(imageView)
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
