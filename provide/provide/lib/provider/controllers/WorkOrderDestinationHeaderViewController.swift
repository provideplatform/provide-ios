//
//  WorkOrderDestinationHeaderViewController.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

class WorkOrderDestinationHeaderViewController: ViewController {

    @IBOutlet private weak var titleImageView: ProfileImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var addressTextView: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()

        navigationController?.navigationBar.backgroundColor = Color.applicationDefaultNavigationBarBackgroundColor()
        navigationController?.navigationBar.barTintColor = nil
        navigationController?.navigationBar.tintColor = nil

        view.addDropShadow(height: 1.25, radius: 2.0, opacity: 0.3)
    }

    func configure(workOrder: WorkOrder?) {
        titleLabel.text = ""
        addressTextView.text = ""

        if let workOrder = workOrder {
            if let user = workOrder.user {
                if let profileImageUrl = user.profileImageUrl {
                    titleImageView.setImageWithUrl(profileImageUrl) { [weak self] in
                        if let strongSelf = self {
                            //strongSelf.activityIndicatorView.stopAnimating()
                            strongSelf.view.bringSubview(toFront: strongSelf.titleImageView)
                            strongSelf.titleImageView.makeCircular()
                            strongSelf.titleImageView.alpha = 1.0
                        }
                    }
                } else {
                    //activityIndicatorView.stopAnimating()

                    titleImageView.image = nil  // TODO: render default profile pic
                    titleImageView.alpha = 0.0
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
