//
//  WorkOrderDestinationHeaderViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

class WorkOrderDestinationHeaderViewController: ViewController {

    @IBOutlet private weak var titleImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var addressTextView: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()

        view.addDropShadow(CGSize(width: 0.0, height: 1.25), radius: CGFloat(2.0), opacity: CGFloat(0.3))
    }

    func configure(workOrder: WorkOrder?) {
        titleLabel.text = ""
        addressTextView.text = ""

        if let workOrder = workOrder {
            if let user = workOrder.user {
                if user.profileImageUrl != nil {
                    // TODO -- load the image view using the profileImageUrl
                } else if user.email != nil {
                    logWarn("Not rendering gravatar image view for work order contact email")
                }

                titleLabel.text = user.name
                if let destination = workOrder.config?["destination"] as? [String: Any] {
                    if let formattedAddress = destination["formatted_address"] as? String {
                        addressTextView.text = formattedAddress
                    } else if let desc = destination["description"] as? String {
                        addressTextView.text = desc
                    }
                }
            }

            addressTextView.sizeToFit()
        }
    }
}
